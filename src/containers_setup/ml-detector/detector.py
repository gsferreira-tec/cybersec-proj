#!/usr/bin/env python3

# ============================================================
# Email Spoofing Detector
# Analyzes email headers + content using:
#   1. Rule-based scoring
#   2. Classical ML (Random Forest)
# Watches /var/mail/new for incoming emails
# ============================================================

import os
import re
import time
import email
import joblib
import numpy as np
from pathlib import Path
from datetime import datetime
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import SVC
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report

LOG_FILE = "/var/log/ml-detector/detector.log"
MAIL_DIR = "/var/mail"
MODEL_DIR = "/var/log/ml-detector"

os.makedirs(MODEL_DIR, exist_ok=True)
os.makedirs(MAIL_DIR, exist_ok=True)


# ============================================================
# Feature extraction from email headers + content
# ============================================================
def extract_features(msg):
    features = {}

    # --- SPF ---
    auth_results = msg.get("Authentication-Results", "")
    received_spf = msg.get("Received-SPF", "")
    features["spf_pass"]     = 1 if "spf=pass"     in auth_results.lower() else 0
    features["spf_fail"]     = 1 if "spf=fail"     in auth_results.lower() or "fail" in received_spf.lower() else 0
    features["spf_softfail"] = 1 if "spf=softfail" in auth_results.lower() or "softfail" in received_spf.lower() else 0
    features["spf_none"]     = 1 if "spf=none"     in auth_results.lower() else 0

    # --- DKIM ---
    features["dkim_pass"] = 1 if "dkim=pass" in auth_results.lower() else 0
    features["dkim_fail"] = 1 if "dkim=fail" in auth_results.lower() else 0
    features["dkim_none"] = 1 if "dkim=none" in auth_results.lower() else 0
    features["has_dkim_signature"] = 1 if msg.get("DKIM-Signature") else 0

    # --- DMARC ---
    features["dmarc_pass"] = 1 if "dmarc=pass" in auth_results.lower() else 0
    features["dmarc_fail"] = 1 if "dmarc=fail" in auth_results.lower() else 0
    features["dmarc_none"] = 1 if "dmarc=none" in auth_results.lower() else 0

    # --- From / Envelope alignment ---
    from_header   = msg.get("From", "")
    return_path   = msg.get("Return-Path", "")
    reply_to      = msg.get("Reply-To", "")

    from_domain   = re.search(r"@([\w.]+)", from_header)
    return_domain = re.search(r"@([\w.]+)", return_path)

    from_domain   = from_domain.group(1).lower()   if from_domain   else ""
    return_domain = return_domain.group(1).lower()  if return_domain else ""

    features["from_return_mismatch"] = 0 if from_domain == return_domain else 1
    features["has_reply_to"]         = 1 if reply_to and reply_to.strip() != from_header.strip() else 0

    # --- Received headers ---
    received = msg.get_all("Received", [])
    features["received_count"] = len(received)

    # Check if first received hop matches From domain
    first_received = received[0] if received else ""
    features["first_hop_mismatch"] = 0 if from_domain in first_received.lower() else 1

    # --- Timestamp anomaly (per Roobal et al.) ---
    date_header = msg.get("Date", "")
    try:
        from email.utils import parsedate_to_datetime
        msg_time   = parsedate_to_datetime(date_header)
        now        = datetime.now(msg_time.tzinfo)
        delay_secs = abs((now - msg_time).total_seconds())
        features["timestamp_delay"] = delay_secs
        features["timestamp_anomaly"] = 1 if delay_secs > 3600 else 0
    except Exception:
        features["timestamp_delay"]   = 0
        features["timestamp_anomaly"] = 0

    # --- Content features ---
    subject = msg.get("Subject", "").lower()
    features["urgent_subject"]   = 1 if any(w in subject for w in ["urgent", "password", "verify", "account", "reset", "click"]) else 0
    features["has_x_mailer"]     = 1 if msg.get("X-Mailer") else 0
    features["swaks_sent"]       = 1 if "swaks" in msg.get("X-Mailer", "").lower() else 0

    body = ""
    if msg.is_multipart():
        for part in msg.walk():
            if part.get_content_type() == "text/plain":
                body += part.get_payload(decode=True).decode("utf-8", errors="ignore")
    else:
        body = msg.get_payload(decode=True)
        body = body.decode("utf-8", errors="ignore") if body else ""

    features["body_length"]    = len(body)
    features["body_has_links"] = 1 if re.search(r"http[s]?://", body) else 0

    return features


def features_to_vector(features):
    keys = [
        "spf_pass", "spf_fail", "spf_softfail", "spf_none",
        "dkim_pass", "dkim_fail", "dkim_none", "has_dkim_signature",
        "dmarc_pass", "dmarc_fail", "dmarc_none",
        "from_return_mismatch", "has_reply_to",
        "received_count", "first_hop_mismatch",
        "timestamp_delay", "timestamp_anomaly",
        "urgent_subject", "has_x_mailer", "swaks_sent",
        "body_length", "body_has_links",
    ]
    return [features.get(k, 0) for k in keys]


# ============================================================
# Rule-based scoring
# ============================================================
def rule_based_score(features):
    score = 0
    reasons = []

    if features["spf_fail"]:
        score += 40
        reasons.append("SPF fail (+40)")
    elif features["spf_softfail"]:
        score += 25
        reasons.append("SPF softfail (+25)")
    elif features["spf_none"]:
        score += 15
        reasons.append("SPF none (+15)")

    if features["dkim_fail"]:
        score += 30
        reasons.append("DKIM fail (+30)")
    elif features["dkim_none"] and not features["has_dkim_signature"]:
        score += 20
        reasons.append("No DKIM record/signature (+20)")

    if features["dmarc_fail"]:
        score += 20
        reasons.append("DMARC fail (+20)")
    elif features["dmarc_none"]:
        score += 10
        reasons.append("DMARC none (+10)")

    if features["from_return_mismatch"]:
        score += 20
        reasons.append("From/Return-Path mismatch (+20)")

    if features["first_hop_mismatch"]:
        score += 15
        reasons.append("First hop mismatch (+15)")

    if features["timestamp_anomaly"]:
        score += 10
        reasons.append("Timestamp anomaly (+10)")

    if features["swaks_sent"]:
        score += 30
        reasons.append("Sent via swaks (+30)")

    if features["urgent_subject"]:
        score += 10
        reasons.append("Urgent subject (+10)")

    verdict = "SPOOFED" if score >= 50 else "LEGITIMATE"
    return verdict, score, reasons


# ============================================================
# ML models — train on synthetic dataset
# ============================================================
def generate_training_data(n=500):
    X, y = [], []
    rng = np.random.default_rng(42)

    # Legitimate emails
    for _ in range(n // 2):
        f = {
            "spf_pass": 1, "spf_fail": 0, "spf_softfail": 0, "spf_none": 0,
            "dkim_pass": 1, "dkim_fail": 0, "dkim_none": 0, "has_dkim_signature": 1,
            "dmarc_pass": 1, "dmarc_fail": 0, "dmarc_none": 0,
            "from_return_mismatch": 0, "has_reply_to": 0,
            "received_count": int(rng.integers(1, 4)),
            "first_hop_mismatch": 0,
            "timestamp_delay": float(rng.integers(0, 600)),
            "timestamp_anomaly": 0,
            "urgent_subject": 0, "has_x_mailer": 0, "swaks_sent": 0,
            "body_length": int(rng.integers(50, 500)),
            "body_has_links": int(rng.integers(0, 2)),
        }
        X.append(features_to_vector(f))
        y.append(0)

    # Spoofed emails
    for _ in range(n // 2):
        spf_type = rng.choice(["fail", "softfail", "none"])
        f = {
            "spf_pass": 0,
            "spf_fail":     1 if spf_type == "fail"     else 0,
            "spf_softfail": 1 if spf_type == "softfail" else 0,
            "spf_none":     1 if spf_type == "none"     else 0,
            "dkim_pass": 0,
            "dkim_fail": int(rng.integers(0, 2)),
            "dkim_none": 1,
            "has_dkim_signature": int(rng.integers(0, 2)),
            "dmarc_pass": 0, "dmarc_fail": int(rng.integers(0, 2)), "dmarc_none": 1,
            "from_return_mismatch": int(rng.integers(0, 2)),
            "has_reply_to": int(rng.integers(0, 2)),
            "received_count": int(rng.integers(1, 3)),
            "first_hop_mismatch": 1,
            "timestamp_delay": float(rng.integers(0, 7200)),
            "timestamp_anomaly": int(rng.integers(0, 2)),
            "urgent_subject": int(rng.integers(0, 2)),
            "has_x_mailer": 1, "swaks_sent": int(rng.integers(0, 2)),
            "body_length": int(rng.integers(10, 200)),
            "body_has_links": int(rng.integers(0, 2)),
        }
        X.append(features_to_vector(f))
        y.append(1)

    return np.array(X), np.array(y)


def train_models():
    X, y = generate_training_data(500)
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    X_train, X_test, y_train, y_test = train_test_split(
        X_scaled, y, test_size=0.2, random_state=42
    )

    rf  = RandomForestClassifier(n_estimators=100, random_state=42)
    svm = SVC(kernel="rbf", probability=True, random_state=42)

    rf.fit(X_train, y_train)
    svm.fit(X_train, y_train)

    log("=== Random Forest ===")
    log(classification_report(y_test, rf.predict(X_test),
        target_names=["Legitimate", "Spoofed"]))

    log("=== SVM ===")
    log(classification_report(y_test, svm.predict(X_test),
        target_names=["Legitimate", "Spoofed"]))

    joblib.dump(rf,     f"{MODEL_DIR}/rf_model.pkl")
    joblib.dump(svm,    f"{MODEL_DIR}/svm_model.pkl")
    joblib.dump(scaler, f"{MODEL_DIR}/scaler.pkl")

    return rf, svm, scaler


def load_models():
    rf_path  = f"{MODEL_DIR}/rf_model.pkl"
    svm_path = f"{MODEL_DIR}/svm_model.pkl"
    sc_path  = f"{MODEL_DIR}/scaler.pkl"

    if os.path.exists(rf_path) and os.path.exists(svm_path):
        return (
            joblib.load(rf_path),
            joblib.load(svm_path),
            joblib.load(sc_path),
        )

    log("[*] Training models for the first time...")
    return train_models()


# ============================================================
# Logging
# ============================================================
def log(msg):
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line)
    with open(LOG_FILE, "a") as f:
        f.write(line + "\n")


# ============================================================
# Analyze a single email file
# ============================================================
def analyze_email(path, rf, svm, scaler):
    with open(path, "rb") as f:
        msg = email.message_from_binary_file(f)

    features  = extract_features(msg)
    vec       = np.array(features_to_vector(features)).reshape(1, -1)
    vec_scaled = scaler.transform(vec)

    # Rule-based
    rb_verdict, rb_score, rb_reasons = rule_based_score(features)

    # ML predictions
    rf_pred  = rf.predict(vec_scaled)[0]
    rf_prob  = rf.predict_proba(vec_scaled)[0][1]
    svm_pred = svm.predict(vec_scaled)[0]
    svm_prob = svm.predict_proba(vec_scaled)[0][1]

    rf_verdict  = "SPOOFED" if rf_pred  == 1 else "LEGITIMATE"
    svm_verdict = "SPOOFED" if svm_pred == 1 else "LEGITIMATE"

    subject = msg.get("Subject", "(no subject)")
    from_h  = msg.get("From", "(unknown)")

    log(f"--- New email ---")
    log(f"  File:    {path}")
    log(f"  From:    {from_h}")
    log(f"  Subject: {subject}")
    log(f"  [Rule-based]  verdict={rb_verdict}  score={rb_score}/100")
    for r in rb_reasons:
        log(f"    • {r}")
    log(f"  [Random Forest] verdict={rf_verdict}  confidence={rf_prob:.2f}")
    log(f"  [SVM]           verdict={svm_verdict}  confidence={svm_prob:.2f}")
    log(f"-----------------")


# ============================================================
# Watch maildir for new emails
# ============================================================
def watch_maildir(rf, svm, scaler):
    log(f"[*] Watching {MAIL_DIR} for new emails...")
    seen = set()

    while True:
        for root, dirs, files in os.walk(MAIL_DIR):
            for fname in files:
                fpath = os.path.join(root, fname)
                if fpath not in seen:
                    seen.add(fpath)
                    try:
                        analyze_email(fpath, rf, svm, scaler)
                    except Exception as e:
                        log(f"[!] Error analyzing {fpath}: {e}")
        time.sleep(5)


# ============================================================
# Main
# ============================================================
if __name__ == "__main__":
    log("[*] Email Spoofing Detector starting...")
    rf, svm, scaler = load_models()
    log("[*] Models ready.")
    watch_maildir(rf, svm, scaler)

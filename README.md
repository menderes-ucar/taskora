# 🚀 Taskora — Premium Freelance Marketplace & Escrow SaaS

Taskora is a modern mobile SaaS platform designed to bridge the gap between employers and freelancers with a secure, trust-driven architecture. It eliminates financial friction by enforcing a strict **Escrow (Guaranteed Payment)** system, version-controlled delivery tracking, and robust backend state management.

---

## 📱 App UI Previews

<p align="center">
  <img src="assets/images/screenshot_1.png" width="28%" alt="Active Jobs" /> &nbsp;&nbsp;&nbsp;
  <img src="assets/images/screenshot_2.png" width="28%" alt="Contract Detail & Escrow" /> &nbsp;&nbsp;&nbsp;
  <img src="assets/images/screenshot_3.png" width="28%" alt="Employer Dashboard" />
</p>

---

## 🌟 Key Features

- 🛡️ **Escrow Financial Security:** Projects cannot move to the active development phase until the employer funds the agreed amount into the platform's secure escrow pool. Funds are only released upon final approval.
- 🔄 **Atomic Database Workflows & RPC:** Handled via robust backend states to ensure zero discrepancies in contract states, proposal acceptances, and wallet transfers.
- 📦 **Version-Controlled Deliveries (v1, v2...):** Freelancers submit their deliverables with notes and external links (GitHub, Figma, Google Drive), maintaining a transparent history of revisions.
- ⏱️ **Audit Log & Transaction Timeline:** Every critical milestone—such as contract creation, funding, submission, revision requests, and final release—is tracked chronologically.
- 🎨 **Minimalist Design System:** Crafted with a clean UI inspired by modern fintech and SaaS standards (Stripe & Linear aesthetic), utilizing a signature turquoise and slate palette.

---

## 🛠️ Architecture & Tech Stack

- **Frontend:** Flutter & Dart (Cross-platform mobile application)
- **State Management:** Riverpod (`AsyncNotifier` and reactive providers for real-time UI synchronization)
- **Backend & Database:** Supabase (PostgreSQL, Realtime subscriptions, Auth, and RPC functions)
- **Navigation & Routing:** Custom generated routing architecture with role-based shell routing (Employer & Freelancer dashboards)

---

## 📱 Core Application Flows

1. **Proposal & Contract Initiation:** Employers review incoming proposals, accept them, and a contract is automatically generated in a `waitingPayment` state.
2. **Escrow Funding:** The employer views the contract detail page and securely locks the funds into the escrow pool (`funded` state) before the freelancer begins working.
3. **Execution & Submission:** The freelancer delivers work versions. If modifications are required, the employer triggers a `revisionRequested` state; otherwise, they approve and release the payment (`completed`).

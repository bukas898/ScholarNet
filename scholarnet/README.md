## 📄 ScholarNet – Academic Research Network Smart Contract

**ScholarNet** is a Clarity smart contract designed for decentralized academic collaboration. It enables researchers to manage their profiles, publish and track academic records, verify academic credentials, and participate in peer reviews within a privacy-controlled, transparent ecosystem.

---

### 🚀 Features

* **Researcher Profiles**: Create, update, and verify academic profiles with customizable privacy levels.
* **Publication Records**: Add and manage academic publications, including title, journal, DOI, and abstract.
* **Academic Credentials**: Record degrees, institutions, graduation dates, and optional field of study with verification support.
* **Peer Reviews**: Submit and receive public or private reviews to support academic trust and reputation.
* **Academic Connections**: Establish professional links with other researchers (pending, accepted, or blocked).
* **Privacy Levels**:

  * `0 (Public)`
  * `1 (Academic Network Only)`
  * `2 (Private)`

---

### 📚 Data Structures

* `researcher-profiles`: Stores researcher info including name, bio, institution, and verification status.
* `publication-records`: Links researchers with their individual publications using unique IDs.
* `academic-credentials`: Tracks verified or unverified educational achievements.
* `peer-reviews`: Allows for decentralized feedback across researchers.
* `academic-connections`: Manages relationships between researchers.

---

### 🧠 Error Codes

* `ERR-NOT-AUTHORIZED (100)`: The caller lacks permission.
* `ERR-RESEARCHER-NOT-FOUND (101)`: Profile must be created before accessing certain features.
* `ERR-ALREADY-ENDORSED (102)`: Attempted duplicate endorsement or connection.
* `ERR-INVALID-PRIVACY-LEVEL (103)`: Submitted privacy level is outside the accepted range.
* `ERR-CREDENTIAL-NOT-FOUND (104)`: Referenced credential does not exist.

---

### 🛠 Example Usage

```clojure
;; Create profile
(create-researcher-profile "Dr. Alice" "Machine Learning Expert" "MIT" u0)

;; Add publication
(add-publication-record "Distributed Learning in Edge Networks" "IEEE Journal" 20250706 none "Study on edge ML." u1)

;; Add academic credential
(add-academic-credential "PhD in CS" "MIT" 20240510 none "https://verify.mit.edu/alice-phd" u0)
```

---

### 🛡 Privacy-first & Open Research

ScholarNet ensures **research integrity**, **transparency**, and **sovereign data control** for academics in Web3 environments. Researchers control what is public, what remains in-network, and what stays private.

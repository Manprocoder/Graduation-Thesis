# Design an efficient ASCON hardware architecture for authenticated encryption and hashing

## 📘 Abstract
The Internet of Things (IoT) is a core technology platform in which sensors are deployed ubiquitously to collect and exchange data with neighboring nodes. Due to their highly interconnected nature, IoT systems are vulnerable to cyberattacks. To mitigate these risks, cryptographic primitives have been considered; however, their computational complexity poses challenges for implementation in resource-constrained IoT environments. Moreover, IoT systems have varying requirements, ranging from high throughput to limited hardware resources. Therefore, selecting an appropriate security mechanism must be carefully considered.

This thesis implements Ascon—the winning algorithm of the NIST Lightweight Cryptography Competition (2019–2023)—as a solution to this issue. The design approach is based on the number of permutation rounds executed per cycle: specifically, 2 rounds per cycle for Ascon-128a mode and 3 rounds per cycle for the remaining modes. The results achieved in terms of Throughput (TP) and Throughput per Area (TP/A) are quite good:

Ascon-128: 410.83 Mbps, TP/A = 0.122

Ascon-128a: 554.15 Mbps, TP/A = 0.165

Ascon-Hash: 165.48 Mbps, TP/A = 0.05

Since the Ascon core in this thesis supports multiple operating modes, a multifunctional DMA is proposed to further enhance system performance. The DMA achieves a maximum operating frequency of 114 MHz, meeting the speed requirements of the system. The DMA’s achieved throughput and TP/A across different modes are as follows:

Ascon-128: 141.11 Mbps, TP/A = 0.14

Ascon-128a: 236.7 Mbps, TP/A = 0.23

Ascon-Hash: 156.12 Mbps, TP/A = 0.15

These results demonstrate the feasibility of deploying the proposed Ascon-based architecture in high-speed and resource-efficient IoT systems.

---

## 📊 Results and Comparison

### Ascon-128 – Comparison Table

| Design          | Device      | Max Freq (MHz) | LUTs     | Throughput (Mbps) | TP/A (Mbps/LUT) |
|----------------|-------------|----------------|----------|--------------------|------------------|
| [1]           | Spartan-6   | 216            | 684      | 60.10              | 0.087            |
| [2]           | Spartan-6   | 146.1          | 1,640    | 114.00             | 0.070            |
| [3]           | Spartan-6   | 174.4          | 1,913    | 1,116.40           | 0.584            |
| [4]           | Artix-7     | 317            | 1,756    | 376.00             | 0.214            |
| [5]           | Kintex-7    | 200            | 1,232    | 948.00             | 0.770            |
| **This Work**  | Artix-7     | 93.08          | 3,358    | 410.83             | 0.122            |


---

### Ascon-128a – Comparison Table

| Design          | Device      | Max Freq (MHz) | LUTs     | Throughput (Mbps) | TP/A (Mbps/LUT) |
|----------------|-------------|----------------|----------|--------------------|------------------|
| [1]           | Spartan-6   | 216            | 684      | 119.16             | 0.174            |
| [2]           | Spartan-6   | 148.4          | 1,725    | 237.40             | 0.138            |
| [4]           | Artix-7     | 317            | 1,756    | 853.00             | 0.486            |
| [5]           | Kintex-7    | 200            | 1,232    | 1,462.86           | 1.190            |
| **This Work**  | Artix-7     | 93.08          | 3,358    | 554.15             | 0.165            |


---

## 🧾 Conclusion

The dense interconnection of IoT sensor nodes in smart city environments poses significant risks of cyberattacks. These attacks can disrupt the overall functioning of smart cities. To mitigate such threats, lightweight cryptographic hardware architectures should be considered for deployment. This thesis implements Ascon, using an architecture based on the number of permutation rounds per cycle, as a solution to this problem.

The design is inspired by the approach in [6], which explores a design space largely overlooked by previous works [1], [2], [3], [4]. The achieved results in terms of Throughput (TP) and Throughput per Area (TP/A) are acceptable, with:

Ascon-128: 371 Mbps, TP/A = 0.115

Ascon-128a: 500 Mbps, TP/A = 0.15

Ascon-Hash: 151.2 Mbps, TP/A = 0.05

To integrate the architecture into a functional system, this thesis further develops a complete system by incorporating a multifunctional DMA controller. This DMA reduces CPU workload, enabling faster system performance, as CPU-based read/write operations to/from Ascon would otherwise be time-consuming. Moreover, the multifunctional DMA supports real-time data formatting to operate various Ascon modes — a capability not possible with basic DMA (which only handles raw read/write).

As a result, the system achieves the following throughput and TP/A metrics across the three Ascon modes:

Ascon-128: 259.42 Mbps, TP/A = 0.027

Ascon-128a: 407.67 Mbps, TP/A = 0.0417

Ascon-Hash: 225.6 Mbps, TP/A = 0.023

These results confirm that the integrated architecture enables high-speed, mode-flexible cryptographic processing suitable for smart city IoT applications.

---

## 📚 References

[1] P. Yalla and J.-P. Kaps, “Evaluation of the CAESAR hardware API for lightweight implementations,” *2017 International Conference on ReConFigurable Computing and FPGAs (ReConFig)*. [DOI:10.1109/RECONFIG.2017.8279790](https://doi.org/10.1109/RECONFIG.2017.8279790)

[2] W. Diehl, F. Farahmand, A. Abdulgadir, J.-P. Kaps, and K. Gaj, “Face-off between the CAESAR lightweight finalists: ACORN vs. Ascon,” *2018 International Conference on Field-Programmable Technology (FPT)*. [DOI:10.1109/FPT.2018.00066](https://doi.org/10.1109/FPT.2018.00066)

[3] B. Rezvani and W. Diehl, “Hardware implementations of NIST lightweight cryptographic candidates: A first look,” *NIST Lightweight Cryptography Workshop*, Cryptology ePrint Archive, Report 2019/824.

[4] A. R. Alharbi, A. Aljaedi, A. Aljuhni, M. K. Alghuson, H. Aldawood, and S. S. Jamal, “Evaluating Ascon Hardware on 7-Series,” *IEEE Xplore*, 2024. [Link](https://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=10701064)

[5] A. Kandi, A. Baksi, T. Gerlich, S. Guilley, P. Gan, J. Breier, A. Chattopadhyay, R. R. Shrivastwa, Z. Martinasek, and S. Bhasin, “Hardware Implementation of ASCON,” *Cryptology ePrint Archive*, Report 2024/984. [PDF](https://eprint.iacr.org/2024/984.pdf)

[6] S. Khan, W.-K. Lee, and S. O. Hwang, “Scalable and efficient hardware architectures for authenticated encryption in IoT applications,” *IEEE Internet of Things Journal*, 2021. [DOI:10.1109/JIOT.2021.3052184](https://doi.org/10.1109/JIOT.2021.3052184)





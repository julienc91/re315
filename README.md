RE315 - Laptop Project
======================

**Important:** If you have not obtained this project by cloning the github
repository, please clone it:

    git clone https://github.com/julienc91/re315


The purpose of this project was to find and implement several methods to
bypass or log password of disk encryption systems. This repository is divided
into 5 parts:

- `luks`: methods targeting the Luks disk encryption system, both on
  Debian and Fedora based operating systems
- `TrueCrypt`: methods targeting TrueCrypt. `Phishing` contains the phishing
method, and `tc-infection` the TrueCrypt bootloader infection.
- `BitLocker`: trick BitLocker when it is used without a TPM
- `usb_key`: source code to create a light and bootable usb key to perform
  the previous attacks and RAM dumps.
- `rapport`: LaTeX source code of the project report

Other `README.md` files are available in subdirectories for more explanations.

If any problem is encountered, do not hesitate to contact us.

### Team

ENSEIRB-MATMECA, RSR, 2013-2014

- Julien CHAUMONT       : jchaumont [at] enseirb-matmeca.fr
- Pierric GOURINCHAS    : pgourinchas [at] enseirb-matmeca.fr
- Antoine HANRIAT       : ahanriat [at] enseirb-matmeca.fr
- Florent MONJALET      : fmonjalet [at] enseirb-matmeca.fr


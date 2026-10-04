<div align="center">

# FitGirl RAR Files Inspector 

![Release](https://img.shields.io/github/v/release/WavierPigeon261/fitgirl-rar-files-inspector?color=blue&style=flat-square)
![License](https://img.shields.io/github/license/WavierPigeon261/fitgirl-rar-files-inspector?style=flat-square)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey?style=flat-square)

</div>

**FitGirl RAR Files Inspector** is a lightweight, high-performance Windows desktop utility built to verify downloaded files and completeness of multi-part RAR archives (`.part01.rar`, `.part02.rar`, etc.) of FitGirl Repacks prior to extraction.

It helps prevent common extraction headaches, corrupt archive errors, and long-path `Unarc.dll` failures before you waste time running installers.

---

## ✨ Features

- **⚡ Instant Multi-Part Integrity Checks:** Scans archive directories to detect missing parts, broken naming sequences, or truncated files.
- **📁 Drag & Drop Interface:** Simply drop any game folder or RAR file directly onto the window to begin inspection.
- **📊 Tabbed Diagnostics:**
  - **Diagnostic Summary:** Rich, color-coded execution logs highlighting system checks, path issues, and drive space.
  - **Individual Parts Breakdown:** A structured DataGrid breakdown displaying file sizes and real-time verification statuses.
- **🛡️ Environment Analysis:** Checks drive free space and flags long directory path lengths (>120 chars) or non-ASCII characters to prevent `Unarc.dll` error `-11`.
- **🌙 Dark Mode Toggle:** Native support for both light and dark UI themes.
- **🚀 One-Click Extraction:** Launch the extraction process directly on `Part 01` straight from the app menu.
- **📦 Zero External Dependencies:** Standalone, single-file native C# binary compiled via .NET Framework.

---

## 🛠️ Installation & Usage

### Quick Start (Pre-compiled Binary)

1. Head over to the **[Releases](../../releases)** page.
2. Download `fitgirl-rar-files-inspector.exe`.
3. Launch the application (no installation required).
4. Drag and drop your downloaded game folder into the application and click **Start Verification**.

---

## 🏗️ Building from Source

You can easily compile the executable locally on any Windows machine using the native C# compiler (`csc.exe`) without needing Visual Studio.

1. Clone the repository:
   ```bash
   git clone https://github.com/WavierPigeon261/fitgirl-rar-files-inspector.git
   cd fitgirl-rar-files-inspector
2. Compile using the .NET Framework C# compiler:
   ```cmd
   csc.exe /target:winexe /out:fitgirl-rar-files-inspector.exe MainForm.cs
   ```
3. The compiled binary fitgirl-rar-files-inspector.exe will be generated in the root directory.

## ⚖️ Disclaimer

> **FitGirl RAR Files Inspector** is an independent open-source diagnostic utility and is not affiliated with, endorsed by, or connected to FitGirl Repacks or any game publisher. 
> 
> This tool does not host, store, or distribute any copyrighted files or content. It operates exclusively as a local file-structure analysis tool. This software is provided "as is" under the MIT License, without warranty of any kind.
> 

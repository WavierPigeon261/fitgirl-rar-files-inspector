# =========================================================
# Native C# Project Generator for FitGirl RAR Files Inspector
# =========================================================

$targetDir = $PSScriptRoot

Write-Host "Generating C# project in: $targetDir" -ForegroundColor Cyan
Write-Host "--------------------------------------------------"

$csharpSource = @'
using System;
using System.IO;
using System.Linq;
using System.Drawing;
using System.Text.RegularExpressions;
using System.Windows.Forms;
using System.Diagnostics;

namespace FitGirlRARInspector
{
    public class MainForm : Form
    {
        private TextBox txtFolderPath;
        private Button btnBrowse;
        private Button btnCheck;
        private ProgressBar progressBar;
        private Label labelTitle;
        private Label labelPrompt;
        private Label labelStatus;
        private RichTextBox logBox;
        private DataGridView gridView;
        private MenuStrip menuStrip;
        private Panel cardPanel;
        private TabControl tabControl;
        private TabPage tabLogs;
        private TabPage tabParts;
        private Label lblDisclaimer;
        private ToolStripMenuItem menuTheme;

        private string selectedFolderPath = "";
        private string detectedPrefix = "";
        private int totalPartsDetected = 0;
        private const long ExpectedStandardSizeBytes = 524288000; // ~500 MB
        private bool isDarkMode = false;

        public MainForm()
        {
            InitializeComponent();
        }

        private void InitializeComponent()
        {
            this.Text = "FitGirl RAR Files Inspector";
            this.ClientSize = new Size(780, 720);
            this.MinimumSize = new Size(680, 620);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.AllowDrop = true;
            this.Font = new Font("Segoe UI", 9.5f, FontStyle.Regular);

            // Drag and Drop support
            this.DragEnter += (s, e) => {
                if (e.Data.GetDataPresent(DataFormats.FileDrop)) e.Effect = DragDropEffects.Copy;
            };
            this.DragDrop += (s, e) => {
                string[] files = (string[])e.Data.GetData(DataFormats.FileDrop);
                if (files.Length > 0)
                {
                    string path = files[0];
                    if (File.Exists(path)) path = Path.GetDirectoryName(path);
                    if (Directory.Exists(path))
                    {
                        selectedFolderPath = path;
                        txtFolderPath.Text = selectedFolderPath;
                        btnCheck.Enabled = true;
                        labelStatus.Text = "Status: Path dropped. Click 'Start Verification'.";
                    }
                }
            };

            // MenuStrip
            menuStrip = new MenuStrip { Font = new Font("Segoe UI", 9f) };
            
            ToolStripMenuItem menuFile = new ToolStripMenuItem("&File");
            menuFile.DropDownItems.Add("&Select Game Folder...", null, (s, e) => SelectGameFolder());
            menuFile.DropDownItems.Add("-");
            menuFile.DropDownItems.Add("E&xit", null, (s, e) => this.Close());

            ToolStripMenuItem menuTools = new ToolStripMenuItem("&Tools");
            menuTools.DropDownItems.Add("&Copy Diagnostics Report", null, (s, e) => CopyReport());
            menuTools.DropDownItems.Add("&Launch Extraction (Part 01)", null, (s, e) => LaunchExtraction());

            menuTheme = new ToolStripMenuItem("Toggle &Dark Mode", null, (s, e) => ToggleDarkMode());
            
            ToolStripMenuItem menuHelp = new ToolStripMenuItem("&Help");
            menuHelp.DropDownItems.Add("About &Author", null, (s, e) => Process.Start("https://wavierpigeon261.github.io"));
            menuHelp.DropDownItems.Add("&GitHub Repository", null, (s, e) => Process.Start("https://github.com/WavierPigeon261"));

            menuStrip.Items.Add(menuFile);
            menuStrip.Items.Add(menuTools);
            menuStrip.Items.Add(menuTheme);
            menuStrip.Items.Add(menuHelp);
            this.MainMenuStrip = menuStrip;
            this.Controls.Add(menuStrip);

            // Container Panel
            cardPanel = new Panel
            {
                Location = new Point(15, 30),
                Size = new Size(750, 675),
                Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right,
                Padding = new Padding(15)
            };
            this.Controls.Add(cardPanel);

            // Header Title
            labelTitle = new Label
            {
                Text = "FitGirl RAR Files Inspector",
                Font = new Font("Segoe UI Semibold", 16, FontStyle.Bold),
                Location = new Point(15, 10),
                AutoSize = true
            };
            cardPanel.Controls.Add(labelTitle);

            labelPrompt = new Label
            {
                Text = "Select or drag & drop the directory containing your downloaded RAR archive parts to inspect integrity.",
                Font = new Font("Segoe UI", 9.5f),
                Location = new Point(17, 42),
                Size = new Size(710, 22)
            };
            cardPanel.Controls.Add(labelPrompt);

            // Folder Controls
            txtFolderPath = new TextBox
            {
                Location = new Point(17, 70),
                Size = new Size(580, 27),
                ReadOnly = true,
                Text = "No folder selected (Drag & Drop supported)...",
                Font = new Font("Segoe UI", 9.5f),
                BorderStyle = BorderStyle.FixedSingle
            };
            cardPanel.Controls.Add(txtFolderPath);

            btnBrowse = new Button
            {
                Text = "Browse...",
                Font = new Font("Segoe UI Semibold", 9.5f, FontStyle.Bold),
                Location = new Point(605, 68),
                Size = new Size(120, 30),
                FlatStyle = FlatStyle.Flat,
                Cursor = Cursors.Hand
            };
            btnBrowse.Click += (s, e) => SelectGameFolder();
            cardPanel.Controls.Add(btnBrowse);

            // Progress Bar
            progressBar = new ProgressBar
            {
                Location = new Point(17, 108),
                Size = new Size(708, 8),
                Anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right
            };
            cardPanel.Controls.Add(progressBar);

            // Status Label
            labelStatus = new Label
            {
                Text = "Status: Waiting for folder selection...",
                Font = new Font("Segoe UI", 9.5f, FontStyle.Italic),
                Location = new Point(17, 122),
                AutoSize = true
            };
            cardPanel.Controls.Add(labelStatus);

            // Tab Control
            tabControl = new TabControl
            {
                Location = new Point(17, 148),
                Size = new Size(708, 385),
                Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right
            };

            tabLogs = new TabPage("Diagnostic Summary");
            tabParts = new TabPage("Individual Parts Breakdown");

            // Rich Log Box
            logBox = new RichTextBox
            {
                Dock = DockStyle.Fill,
                Font = new Font("Segoe UI", 9.5f),
                ReadOnly = true,
                BorderStyle = BorderStyle.None,
                WordWrap = false,
                Padding = new Padding(10)
            };
            tabLogs.Controls.Add(logBox);

            // GridView Breakdown
            gridView = new DataGridView
            {
                Dock = DockStyle.Fill,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                AllowUserToAddRows = false,
                ReadOnly = true,
                RowHeadersVisible = false,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                BorderStyle = BorderStyle.None
            };
            gridView.Columns.Add("FileName", "File Name");
            gridView.Columns.Add("Size", "Size (MB)");
            gridView.Columns.Add("Status", "Status");
            tabParts.Controls.Add(gridView);

            tabControl.TabPages.Add(tabLogs);
            tabControl.TabPages.Add(tabParts);
            cardPanel.Controls.Add(tabControl);

            // Action Button
            btnCheck = new Button
            {
                Text = "Start Verification",
                Font = new Font("Segoe UI Semibold", 10.5f, FontStyle.Bold),
                Location = new Point(17, 542),
                Size = new Size(708, 40),
                Anchor = AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right,
                FlatStyle = FlatStyle.Flat,
                Enabled = false,
                Cursor = Cursors.Hand
            };
            btnCheck.Click += (s, e) => CheckFiles();
            cardPanel.Controls.Add(btnCheck);

            // Disclaimer Footer
            lblDisclaimer = new Label
            {
                Text = "Disclaimer: FitGirl RAR Files Inspector is an independent open-source diagnostic utility and is not affiliated with, endorsed by, or connected to FitGirl Repacks or any game publisher. This tool does not host or distribute copyrighted files.",
                Font = new Font("Segoe UI", 8f, FontStyle.Italic),
                Location = new Point(17, 590),
                Size = new Size(708, 35),
                Anchor = AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right,
                TextAlign = ContentAlignment.TopCenter
            };
            cardPanel.Controls.Add(lblDisclaimer);

            ApplyThemeColors();
        }

        private void ToggleDarkMode()
        {
            isDarkMode = !isDarkMode;
            ApplyThemeColors();
        }

        private void ApplyThemeColors()
        {
            if (isDarkMode)
            {
                this.BackColor = Color.FromArgb(18, 18, 18);
                cardPanel.BackColor = Color.FromArgb(30, 30, 30);
                menuStrip.BackColor = Color.FromArgb(30, 30, 30);
                menuStrip.ForeColor = Color.White;
                labelTitle.ForeColor = Color.White;
                labelPrompt.ForeColor = Color.FromArgb(180, 180, 180);
                txtFolderPath.BackColor = Color.FromArgb(45, 45, 45);
                txtFolderPath.ForeColor = Color.White;
                btnBrowse.BackColor = Color.FromArgb(50, 50, 50);
                btnBrowse.ForeColor = Color.White;
                logBox.BackColor = Color.FromArgb(24, 24, 24);
                gridView.BackColor = Color.FromArgb(24, 24, 24);
                gridView.DefaultCellStyle.BackColor = Color.FromArgb(30, 30, 30);
                gridView.DefaultCellStyle.ForeColor = Color.White;
                btnCheck.BackColor = Color.FromArgb(37, 99, 235);
                btnCheck.ForeColor = Color.White;
                lblDisclaimer.ForeColor = Color.FromArgb(140, 140, 140);
            }
            else
            {
                this.BackColor = Color.FromArgb(249, 250, 251);
                cardPanel.BackColor = Color.White;
                menuStrip.BackColor = Color.FromArgb(249, 250, 251);
                menuStrip.ForeColor = Color.Black;
                labelTitle.ForeColor = Color.FromArgb(17, 24, 39);
                labelPrompt.ForeColor = Color.FromArgb(107, 114, 128);
                txtFolderPath.BackColor = Color.FromArgb(243, 244, 246);
                txtFolderPath.ForeColor = Color.FromArgb(75, 85, 99);
                btnBrowse.BackColor = Color.FromArgb(243, 244, 246);
                btnBrowse.ForeColor = Color.FromArgb(31, 41, 55);
                logBox.BackColor = Color.FromArgb(250, 251, 252);
                gridView.BackColor = Color.White;
                gridView.DefaultCellStyle.BackColor = Color.White;
                gridView.DefaultCellStyle.ForeColor = Color.Black;
                btnCheck.BackColor = Color.FromArgb(37, 99, 235);
                btnCheck.ForeColor = Color.White;
                lblDisclaimer.ForeColor = Color.FromArgb(107, 114, 128);
            }
        }

        private void AppendLog(string text, Color color, bool isBold = false)
        {
            logBox.SelectionStart = logBox.TextLength;
            logBox.SelectionLength = 0;
            logBox.SelectionColor = color;
            logBox.SelectionFont = new Font("Segoe UI", 9.5f, isBold ? FontStyle.Bold : FontStyle.Regular);
            logBox.AppendText(text + "\n");
            logBox.SelectionColor = logBox.ForeColor;
            logBox.ScrollToCaret();
        }

        private void SelectGameFolder()
        {
            using (FolderBrowserDialog fbd = new FolderBrowserDialog())
            {
                fbd.Description = "Select the folder containing your downloaded game RAR parts";
                fbd.ShowNewFolderButton = false;
                if (fbd.ShowDialog() == DialogResult.OK)
                {
                    selectedFolderPath = fbd.SelectedPath;
                    txtFolderPath.Text = selectedFolderPath;
                    btnCheck.Enabled = true;
                    labelStatus.Text = "Status: Ready to analyze.";
                }
            }
        }

        private void CopyReport()
        {
            if (!string.IsNullOrEmpty(logBox.Text))
            {
                Clipboard.SetText(logBox.Text);
                MessageBox.Show("Diagnostics report copied to clipboard!", "Copied", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
        }

        private void LaunchExtraction()
        {
            if (string.IsNullOrEmpty(selectedFolderPath))
            {
                MessageBox.Show("Please select a folder first!", "Notice", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }
            string firstPart = Path.Combine(selectedFolderPath, detectedPrefix + "01.rar");
            if (File.Exists(firstPart))
            {
                Process.Start(firstPart);
            }
            else
            {
                MessageBox.Show("Cannot launch extraction: Part 01 was not found in the selected folder.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void RunDiagnostics()
        {
            AppendLog("=== SYSTEM & ENVIRONMENT DIAGNOSTICS ===", Color.FromArgb(79, 70, 229), true);

            DriveInfo drive = new DriveInfo(Path.GetPathRoot(selectedFolderPath));
            double freeSpaceGB = Math.Round((double)drive.AvailableFreeSpace / (1024 * 1024 * 1024), 2);
            AppendLog("Target Drive Space      : " + freeSpaceGB + " GB Free on " + drive.Name + " (" + drive.DriveFormat + ")", Color.FromArgb(55, 65, 81));

            if (selectedFolderPath.Length > 120)
            {
                AppendLog("[WARNING] Directory path length is long (" + selectedFolderPath.Length + " chars). Move closer to root (e.g. C:\\Games) to avoid Unarc.dll error -11.", Color.FromArgb(217, 119, 6));
            }

            if (Regex.IsMatch(selectedFolderPath, @"[^\x00-\x7F]"))
            {
                AppendLog("[WARNING] Path contains non-ASCII characters. Rename path using standard ASCII text.", Color.FromArgb(217, 119, 6));
            }

            AppendLog("--------------------------------------------------------------------------------", Color.FromArgb(229, 231, 235));
        }

        private void CheckFiles()
        {
            if (string.IsNullOrEmpty(selectedFolderPath) || !Directory.Exists(selectedFolderPath))
            {
                MessageBox.Show("Please select a valid folder containing RAR parts.", "Folder Required", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            btnCheck.Enabled = false;
            btnBrowse.Enabled = false;
            logBox.Clear();
            gridView.Rows.Clear();

            labelStatus.Text = "Scanning directory structure...";
            this.Refresh();

            string[] files = Directory.GetFiles(selectedFolderPath, "*.part*.rar");
            if (files.Length == 0)
            {
                AppendLog("[ERROR] No multi-part RAR files (.part01.rar, etc.) detected in this folder.", Color.FromArgb(220, 38, 38), true);
                labelStatus.Text = "Status: No archive parts detected.";
                btnCheck.Enabled = true;
                btnBrowse.Enabled = true;
                return;
            }

            int maxPart = 0;
            string prefix = "";
            Regex regex = new Regex(@"^(.+\.part)(\d+)\.rar$", RegexOptions.IgnoreCase);

            foreach (string filePath in files)
            {
                string fileName = Path.GetFileName(filePath);
                Match match = regex.Match(fileName);
                if (match.Success)
                {
                    prefix = match.Groups[1].Value;
                    int num = int.Parse(match.Groups[2].Value);
                    if (num > maxPart) maxPart = num;
                }
            }

            if (maxPart == 0)
            {
                AppendLog("[ERROR] Could not parse standard archive part numbering.", Color.FromArgb(220, 38, 38), true);
                btnCheck.Enabled = true;
                btnBrowse.Enabled = true;
                return;
            }

            detectedPrefix = prefix;
            totalPartsDetected = maxPart;

            RunDiagnostics();

            AppendLog("=== ARCHIVE SUMMARY ===", Color.FromArgb(79, 70, 229), true);
            AppendLog("Archive Prefix : " + detectedPrefix, Color.FromArgb(55, 65, 81));
            AppendLog("Total Parts    : " + totalPartsDetected + " parts", Color.FromArgb(55, 65, 81));
            AppendLog("--------------------------------------------------------------------------------", Color.FromArgb(229, 231, 235));
            AppendLog("=== INTEGRITY VERIFICATION ===", Color.FromArgb(79, 70, 229), true);

            progressBar.Maximum = totalPartsDetected;
            progressBar.Value = 0;

            int missingCount = 0;
            int corruptCount = 0;

            for (int i = 1; i <= totalPartsDetected; i++)
            {
                string numStr = i.ToString("D2");
                string expectedFileName = detectedPrefix + numStr + ".rar";
                string fullPath = Path.Combine(selectedFolderPath, expectedFileName);

                if (!File.Exists(fullPath))
                {
                    AppendLog("[MISSING] " + expectedFileName, Color.FromArgb(220, 38, 38), true);
                    gridView.Rows.Add(expectedFileName, "0", "MISSING");
                    missingCount++;
                }
                else
                {
                    FileInfo fi = new FileInfo(fullPath);
                    double sizeMB = Math.Round((double)fi.Length / (1024 * 1024), 2);

                    if (i < totalPartsDetected && fi.Length < (ExpectedStandardSizeBytes * 0.95))
                    {
                        AppendLog("[INCOMPLETE] " + expectedFileName + " (" + sizeMB + " MB - expected ~500 MB)", Color.FromArgb(217, 119, 6));
                        gridView.Rows.Add(expectedFileName, sizeMB.ToString(), "INCOMPLETE");
                        corruptCount++;
                    }
                    else
                    {
                        gridView.Rows.Add(expectedFileName, sizeMB.ToString(), "OK");
                    }
                }

                progressBar.Value = i;
                this.Refresh();
                System.Threading.Thread.Sleep(5);
            }

            AppendLog("--------------------------------------------------------------------------------", Color.FromArgb(229, 231, 235));

            if (missingCount == 0 && corruptCount == 0)
            {
                labelStatus.Text = "Status: Perfect! All " + totalPartsDetected + " parts verified successfully.";
                AppendLog("[OK] All " + totalPartsDetected + " parts are present and passed integrity checks.", Color.FromArgb(22, 163, 74), true);
                AppendLog("[ACTION] Ready to extract! Select Tools -> Launch Extraction (Part 01) to begin.", Color.FromArgb(37, 99, 235));
            }
            else
            {
                labelStatus.Text = "Status: Issues Detected (" + missingCount + " missing, " + corruptCount + " truncated)";
                AppendLog("[SUMMARY] " + missingCount + " missing part(s), " + corruptCount + " incomplete part(s).", Color.FromArgb(220, 38, 38), true);
            }

            btnCheck.Enabled = true;
            btnBrowse.Enabled = true;
            btnCheck.Text = "Re-check Selected Folder";
        }

        [STAThread]
        public static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }
}
'@

# Save C# Source
$csPath = "$targetDir\MainForm.cs"
Set-Content -Path $csPath -Value $csharpSource -Encoding UTF8

# Find C# Compiler
$csc = Get-ChildItem -Path "$env:Windir\Microsoft.NET\Framework*\v4.0.*\csc.exe" | Select-Object -First 1 -ExpandProperty FullName

if (-not $csc) {
    Write-Host "Error: C# compiler (csc.exe) not found on this system." -ForegroundColor Red
    pause
    exit
}

# Output file name: fitgirl-rar-files-inspector.exe
$outputExe = "$targetDir\fitgirl-rar-files-inspector.exe"

Write-Host "Compiling FitGirl RAR Files Inspector..." -ForegroundColor Cyan

# Compile C# WinForms EXE
Start-Process -FilePath $csc -ArgumentList "/target:winexe", "/r:System.Windows.Forms.dll", "/r:System.Drawing.dll", "/r:System.Data.dll", "/out:`"$outputExe`"", "`"$csPath`"" -Wait -NoNewWindow

if (Test-Path $outputExe) {
    Write-Host "--------------------------------------------------" -ForegroundColor Green
    Write-Host "SUCCESS: Executable compiled at:" -ForegroundColor Green
    Write-Host "$outputExe" -ForegroundColor Yellow
} else {
    Write-Host "`nCompilation failed." -ForegroundColor Red
}
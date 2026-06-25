using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

namespace TMKKeyboardInstaller
{
    internal static class Program
    {
        [STAThread]
        private static void Main(string[] args)
        {
#if UNINSTALLER
            bool uninstall = true;
#else
            bool uninstall = args.Length > 0 &&
                string.Equals(args[0], "/uninstall", StringComparison.OrdinalIgnoreCase);
#endif

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new InstallerForm(uninstall));
        }
    }

    internal sealed class InstallerForm : Form
    {
        private readonly bool uninstallMode;
        private readonly Label statusLabel;
        private readonly Label detailLabel;
        private readonly ProgressBar progressBar;
        private readonly RichTextBox activityLog;
        private readonly Button actionButton;
        private readonly Button closeButton;
        private readonly Label[] stepLabels;
        private readonly string workingDirectory;
        private Process worker;

        private static readonly Color HeaderGreen = Color.FromArgb(2, 65, 37);
        private static readonly Color AccentBlue = Color.FromArgb(0, 91, 234);
        private static readonly Color SuccessGreen = Color.FromArgb(20, 125, 69);
        private static readonly Color TextPrimary = Color.FromArgb(35, 42, 48);
        private static readonly Color TextSecondary = Color.FromArgb(95, 105, 115);
        private static readonly Color Border = Color.FromArgb(218, 223, 228);

        public InstallerForm(bool uninstall)
        {
            uninstallMode = uninstall;
            workingDirectory = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "Temp",
                "TMKKeyboardPro",
                Guid.NewGuid().ToString("N"));
            Text = uninstall ? "Uninstall TMK Keyboard Pro" : "Install TMK Keyboard Pro";
            ClientSize = new Size(720, 570);
            MinimumSize = new Size(640, 520);
            StartPosition = FormStartPosition.CenterScreen;
            BackColor = Color.White;
            Font = new Font("Segoe UI", 9F);
            FormBorderStyle = FormBorderStyle.Sizable;
            MaximizeBox = true;
            Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);

            Panel header = BuildHeader();
            Controls.Add(header);

            TableLayoutPanel body = new TableLayoutPanel();
            body.Dock = DockStyle.Fill;
            body.Padding = new Padding(28, 22, 28, 22);
            body.ColumnCount = 1;
            body.RowCount = 6;
            body.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            body.RowStyles.Add(new RowStyle(SizeType.Absolute, 38F));
            body.RowStyles.Add(new RowStyle(SizeType.Absolute, 48F));
            body.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            body.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
            body.RowStyles.Add(new RowStyle(SizeType.Absolute, 58F));

            Panel statusPanel = new Panel();
            statusPanel.Dock = DockStyle.Fill;
            statusPanel.Height = 58;

            statusLabel = new Label();
            statusLabel.AutoSize = true;
            statusLabel.Font = new Font("Segoe UI", 15F, FontStyle.Bold);
            statusLabel.ForeColor = TextPrimary;
            statusLabel.Text = uninstall ? "Ready to remove" : "Ready to install";
            statusLabel.Location = new Point(0, 0);

            detailLabel = new Label();
            detailLabel.AutoSize = true;
            detailLabel.Font = new Font("Segoe UI", 9.5F);
            detailLabel.ForeColor = TextSecondary;
            detailLabel.Text = uninstall
                ? "Remove TMK Keyboard Pro from this Windows account."
                : "Add English - Shan (TMK) and switch with Win + Space.";
            detailLabel.Location = new Point(1, 34);

            statusPanel.Controls.Add(statusLabel);
            statusPanel.Controls.Add(detailLabel);
            body.Controls.Add(statusPanel, 0, 0);

            progressBar = new ProgressBar();
            progressBar.Dock = DockStyle.Fill;
            progressBar.Minimum = 0;
            progressBar.Maximum = 100;
            progressBar.Value = 0;
            progressBar.Style = ProgressBarStyle.Continuous;
            progressBar.Margin = new Padding(0, 8, 0, 8);
            body.Controls.Add(progressBar, 0, 1);

            FlowLayoutPanel steps = new FlowLayoutPanel();
            steps.Dock = DockStyle.Fill;
            steps.FlowDirection = FlowDirection.LeftToRight;
            steps.WrapContents = false;
            steps.Padding = new Padding(0, 4, 0, 4);
            stepLabels = new[]
            {
                CreateStep("1  Prepare"),
                CreateStep("2  Files"),
                CreateStep("3  Windows profile"),
                CreateStep("4  Complete")
            };
            foreach (Label step in stepLabels)
            {
                steps.Controls.Add(step);
            }
            HighlightStep(0);
            body.Controls.Add(steps, 0, 2);

            Label activityTitle = new Label();
            activityTitle.AutoSize = true;
            activityTitle.Font = new Font("Segoe UI Semibold", 10F, FontStyle.Bold);
            activityTitle.ForeColor = TextPrimary;
            activityTitle.Text = "Activity";
            activityTitle.Margin = new Padding(0, 8, 0, 6);
            body.Controls.Add(activityTitle, 0, 3);

            activityLog = new RichTextBox();
            activityLog.Dock = DockStyle.Fill;
            activityLog.ReadOnly = true;
            activityLog.BackColor = Color.FromArgb(248, 249, 250);
            activityLog.ForeColor = TextPrimary;
            activityLog.BorderStyle = BorderStyle.FixedSingle;
            activityLog.Font = new Font("Consolas", 9F);
            activityLog.DetectUrls = false;
            activityLog.TabStop = false;
            activityLog.Text = uninstall
                ? "TMK Keyboard Pro is ready to be removed.\r\n"
                : "TMK Keyboard Pro is ready to install.\r\n";
            body.Controls.Add(activityLog, 0, 4);

            FlowLayoutPanel footer = new FlowLayoutPanel();
            footer.Dock = DockStyle.Fill;
            footer.FlowDirection = FlowDirection.RightToLeft;
            footer.WrapContents = false;
            footer.Padding = new Padding(0, 12, 0, 0);

            actionButton = CreateButton(
                uninstall ? "Uninstall keyboard" : "Install keyboard",
                AccentBlue,
                Color.White);
            actionButton.Click += StartOperation;

            closeButton = CreateButton("Close", Color.White, TextPrimary);
            closeButton.FlatAppearance.BorderColor = Border;
            closeButton.Click += delegate { Close(); };

            footer.Controls.Add(actionButton);
            footer.Controls.Add(closeButton);
            body.Controls.Add(footer, 0, 5);

            Controls.Add(body);
            body.BringToFront();
            FormClosing += OnFormClosing;
            FormClosed += delegate { TryCleanup(); };
        }

        private Panel BuildHeader()
        {
            Panel header = new Panel();
            header.Dock = DockStyle.Top;
            header.Height = 138;
            header.BackColor = HeaderGreen;

            PictureBox logo = new PictureBox();
            logo.Location = new Point(24, 18);
            logo.Size = new Size(102, 102);
            logo.SizeMode = PictureBoxSizeMode.Zoom;
            logo.Anchor = AnchorStyles.Top | AnchorStyles.Left;
            Image logoImage = LoadEmbeddedImage("TMK.Icon");
            if (logoImage != null)
            {
                logo.Image = logoImage;
            }

            Label title = new Label();
            title.AutoSize = true;
            title.Font = new Font("Segoe UI", 23F, FontStyle.Bold);
            title.ForeColor = Color.White;
            title.Text = "TMK Keyboard Pro";
            title.Location = new Point(146, 30);

            Label subtitle = new Label();
            subtitle.AutoSize = true;
            subtitle.Font = new Font("Segoe UI", 10.5F);
            subtitle.ForeColor = Color.FromArgb(218, 236, 226);
            subtitle.Text = uninstallMode
                ? "Windows keyboard removal"
                : "Shan Unicode keyboard for Windows";
            subtitle.Location = new Point(149, 78);

            Label badge = new Label();
            badge.AutoSize = true;
            badge.Font = new Font("Segoe UI", 8.5F, FontStyle.Bold);
            badge.ForeColor = Color.FromArgb(255, 218, 0);
            badge.Text = uninstallMode ? "UNINSTALLER" : "VERSION 1.0";
            badge.Location = new Point(151, 103);

            header.Controls.Add(logo);
            header.Controls.Add(title);
            header.Controls.Add(subtitle);
            header.Controls.Add(badge);
            return header;
        }

        private static Label CreateStep(string text)
        {
            Label label = new Label();
            label.AutoSize = false;
            label.Size = new Size(148, 30);
            label.TextAlign = ContentAlignment.MiddleCenter;
            label.Text = text;
            label.Font = new Font("Segoe UI", 8.5F, FontStyle.Bold);
            label.ForeColor = TextSecondary;
            label.BackColor = Color.FromArgb(245, 246, 248);
            label.BorderStyle = BorderStyle.FixedSingle;
            label.Margin = new Padding(0, 0, 8, 0);
            return label;
        }

        private static Button CreateButton(string text, Color backColor, Color foreColor)
        {
            Button button = new Button();
            button.AutoSize = false;
            button.Size = new Size(148, 38);
            button.Text = text;
            button.Font = new Font("Segoe UI", 9.5F, FontStyle.Bold);
            button.BackColor = backColor;
            button.ForeColor = foreColor;
            button.FlatStyle = FlatStyle.Flat;
            button.FlatAppearance.BorderSize = 1;
            button.FlatAppearance.BorderColor = backColor;
            button.Cursor = Cursors.Hand;
            button.Margin = new Padding(10, 0, 0, 0);
            return button;
        }

        private void StartOperation(object sender, EventArgs e)
        {
            actionButton.Enabled = false;
            closeButton.Enabled = false;
            progressBar.Value = 2;
            statusLabel.ForeColor = TextPrimary;
            statusLabel.Text = uninstallMode ? "Removing keyboard..." : "Installing keyboard...";
            detailLabel.Text = "Please keep this window open while Windows is updated.";
            activityLog.Clear();
            AppendLog(uninstallMode ? "Starting uninstall." : "Starting installation.", TextPrimary);
            HighlightStep(0);

            string scriptPath;
            try
            {
                scriptPath = PreparePayload();
            }
            catch (Exception ex)
            {
                Finish(false, ex.Message);
                return;
            }

            ProcessStartInfo info = new ProcessStartInfo();
            info.FileName = GetPowerShellPath();
            info.Arguments = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"" +
                scriptPath + "\"";
            info.WorkingDirectory = workingDirectory;
            info.UseShellExecute = false;
            info.CreateNoWindow = true;
            info.RedirectStandardOutput = true;
            info.RedirectStandardError = true;
            info.StandardOutputEncoding = System.Text.Encoding.UTF8;
            info.StandardErrorEncoding = System.Text.Encoding.UTF8;

            worker = new Process();
            worker.StartInfo = info;
            worker.EnableRaisingEvents = true;
            worker.OutputDataReceived += delegate(object processSender, DataReceivedEventArgs args)
            {
                if (!string.IsNullOrEmpty(args.Data))
                {
                    BeginInvoke((MethodInvoker)delegate { HandleOutput(args.Data, false); });
                }
            };
            worker.ErrorDataReceived += delegate(object processSender, DataReceivedEventArgs args)
            {
                if (!string.IsNullOrEmpty(args.Data))
                {
                    BeginInvoke((MethodInvoker)delegate { HandleOutput(args.Data, true); });
                }
            };
            worker.Exited += delegate
            {
                int exitCode = worker.ExitCode;
                BeginInvoke((MethodInvoker)delegate
                {
                    Finish(exitCode == 0, exitCode == 0
                        ? (uninstallMode
                            ? "TMK Keyboard Pro was removed successfully."
                            : "TMK Keyboard Pro is ready. Use Win + Space to select English - Shan (TMK).")
                        : "The operation failed. Review the activity log for details.");
                });
            };

            try
            {
                worker.Start();
                worker.BeginOutputReadLine();
                worker.BeginErrorReadLine();
            }
            catch (Exception ex)
            {
                Finish(false, ex.Message);
            }
        }

        private void HandleOutput(string line, bool isError)
        {
            const string marker = "[TMK_PROGRESS]";
            if (line.StartsWith(marker, StringComparison.Ordinal))
            {
                string payload = line.Substring(marker.Length);
                string[] parts = payload.Split(new[] { '|' }, 2);
                int progress;
                if (parts.Length == 2 && int.TryParse(parts[0], out progress))
                {
                    progress = Math.Max(0, Math.Min(100, progress));
                    progressBar.Value = progress;
                    detailLabel.Text = parts[1];
                    HighlightStep(progress < 25 ? 0 : progress < 55 ? 1 : progress < 90 ? 2 : 3);
                    AppendLog(parts[1], TextPrimary);
                }
                return;
            }

            AppendLog(line, isError ? Color.FromArgb(180, 38, 38) : TextSecondary);
        }

        private void Finish(bool success, string message)
        {
            progressBar.Value = success ? 100 : Math.Max(progressBar.Value, 5);
            statusLabel.Text = success
                ? (uninstallMode ? "Removal complete" : "Installation complete")
                : "Something went wrong";
            statusLabel.ForeColor = success ? SuccessGreen : Color.FromArgb(180, 38, 38);
            detailLabel.Text = message;
            AppendLog(message, success ? SuccessGreen : Color.FromArgb(180, 38, 38));
            HighlightStep(success ? 3 : Math.Max(0, CurrentStep()));

            actionButton.Text = success
                ? "Done"
                : (uninstallMode ? "Try uninstall again" : "Try again");
            actionButton.Enabled = !success;
            closeButton.Enabled = true;
            closeButton.Text = success ? "Close" : "Close";
            if (success)
            {
                closeButton.BackColor = AccentBlue;
                closeButton.ForeColor = Color.White;
                closeButton.FlatAppearance.BorderColor = AccentBlue;
                closeButton.Focus();
            }
        }

        private int CurrentStep()
        {
            int progress = progressBar.Value;
            return progress < 25 ? 0 : progress < 55 ? 1 : progress < 90 ? 2 : 3;
        }

        private void HighlightStep(int activeIndex)
        {
            for (int i = 0; i < stepLabels.Length; i++)
            {
                bool active = i == activeIndex;
                bool complete = i < activeIndex;
                stepLabels[i].BackColor = active
                    ? AccentBlue
                    : complete ? Color.FromArgb(229, 244, 235) : Color.FromArgb(245, 246, 248);
                stepLabels[i].ForeColor = active
                    ? Color.White
                    : complete ? SuccessGreen : TextSecondary;
            }
        }

        private void AppendLog(string text, Color color)
        {
            if (string.IsNullOrWhiteSpace(text))
            {
                return;
            }

            activityLog.SelectionStart = activityLog.TextLength;
            activityLog.SelectionLength = 0;
            activityLog.SelectionColor = Color.FromArgb(140, 148, 156);
            activityLog.AppendText(DateTime.Now.ToString("HH:mm:ss") + "  ");
            activityLog.SelectionColor = color;
            activityLog.AppendText(text.Trim() + Environment.NewLine);
            activityLog.SelectionColor = activityLog.ForeColor;
            activityLog.ScrollToCaret();
        }

        private static string GetPowerShellPath()
        {
            string windows = Environment.GetFolderPath(Environment.SpecialFolder.Windows);
            if (Environment.Is64BitOperatingSystem && !Environment.Is64BitProcess)
            {
                string sysnative = Path.Combine(
                    windows,
                    "Sysnative",
                    "WindowsPowerShell",
                    "v1.0",
                    "powershell.exe");
                if (File.Exists(sysnative))
                {
                    return sysnative;
                }
            }

            return Path.Combine(
                windows,
                "System32",
                "WindowsPowerShell",
                "v1.0",
                "powershell.exe");
        }

        private string PreparePayload()
        {
            Directory.CreateDirectory(workingDirectory);
            if (uninstallMode)
            {
                string uninstallScript = Path.Combine(workingDirectory, "uninstall.ps1");
                ExtractResource("TMK.UninstallScript", uninstallScript);
                return uninstallScript;
            }

            string installScript = Path.Combine(workingDirectory, "install.ps1");
            ExtractResource("TMK.InstallScript", installScript);
            ExtractResource("TMK.NativeAmd64", Path.Combine(workingDirectory, "TMKSHAN-amd64.dll"));
            ExtractResource("TMK.NativeI386", Path.Combine(workingDirectory, "TMKSHAN-i386.dll"));
            ExtractResource("TMK.Wow64", Path.Combine(workingDirectory, "TMKSHAN-wow64.dll"));
            return installScript;
        }

        private static void ExtractResource(string resourceName, string destination)
        {
            Assembly assembly = Assembly.GetExecutingAssembly();
            using (Stream input = assembly.GetManifestResourceStream(resourceName))
            {
                if (input == null)
                {
                    throw new InvalidOperationException(
                        "Installer resource is missing: " + resourceName);
                }

                using (FileStream output = new FileStream(
                    destination,
                    FileMode.Create,
                    FileAccess.Write,
                    FileShare.None))
                {
                    input.CopyTo(output);
                }
            }
        }

        private static Image LoadEmbeddedImage(string resourceName)
        {
            Assembly assembly = Assembly.GetExecutingAssembly();
            using (Stream input = assembly.GetManifestResourceStream(resourceName))
            {
                if (input == null)
                {
                    return null;
                }

                using (Image source = Image.FromStream(input))
                {
                    return new Bitmap(source);
                }
            }
        }

        private void TryCleanup()
        {
            try
            {
                if (Directory.Exists(workingDirectory))
                {
                    Directory.Delete(workingDirectory, true);
                }
            }
            catch
            {
            }
        }

        private void OnFormClosing(object sender, FormClosingEventArgs e)
        {
            if (worker != null && !worker.HasExited)
            {
                e.Cancel = true;
                System.Media.SystemSounds.Beep.Play();
                detailLabel.Text = "Please wait for the current Windows update to finish.";
            }
        }
    }
}

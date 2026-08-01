import os
import subprocess
from PyQt5.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel, QLineEdit,
    QPushButton, QTextEdit, QMessageBox, QFileDialog,
    QSlider, QScrollArea, QGroupBox, QCheckBox, QComboBox,
    QRadioButton, QButtonGroup
)
from PyQt5.QtCore import QThread, pyqtSignal, Qt

class PipelineRunnerThread(QThread):
    logSignal = pyqtSignal(str)
    finishedSignal = pyqtSignal(bool)

    def __init__(self, workflow, input_file, reference_file=None, cores=2,
                 profiles=None, enable_bqsr=False, enable_metrics=False, vcf_files=None,
                 bundleVcf=None, variantMode="defaults", aligner="default"):
        super().__init__()
        self.workflow = workflow
        self.input_file = input_file
        self.reference_file = reference_file
        self.cores = cores
        self.profiles = profiles or []
        self.enable_bqsr = enable_bqsr
        self.vcf_files = vcf_files or []
        self.bundleVcf = bundleVcf or []
        self.variantMode = variantMode
        self.aligner = aligner
        self.process = None
        self.enable_metrics = enable_metrics

    def run(self):
        try:
            if not os.path.exists(self.workflow):
                self.logSignal.emit(f"Error: Workflow file '{self.workflow}' does not exist.\n")
                self.finishedSignal.emit(False)
                return

            cmd = ["nextflow", "run", self.workflow, "--fullmode", "--input", self.input_file]

            if self.reference_file:
                cmd.extend(["--reference", self.reference_file])

            if self.profiles:
                cmd.extend(["-profile", ",".join(self.profiles)])

            if self.enable_bqsr:
                cmd.append("--bqsr")
                if self.bundleVcf:  # Using pre-bundled VCFs
                    if len(self.bundleVcf) > 0:  # First VCF if available
                        cmd.extend(["--ivcf1", self.bundleVcf[0]])
                        if len(self.bundleVcf) > 1:  # Second VCF if available
                            cmd.extend(["--ivcf2", self.bundleVcf[1]])
                else:  # Using local VCF files
                    if self.vcf_files and len(self.vcf_files) > 0:
                        cmd.extend(["--knownsite1", self.vcf_files[0]])
                        if len(self.vcf_files) > 1:
                            cmd.extend(["--knownsite2", self.vcf_files[1]])

            if self.variantMode != "defaults":
                cmd.extend(["--mode", self.variantMode])

            if self.aligner != "default":
                cmd.extend(["--aligner", self.aligner])

            if  self.enable_metrics:
                cmd.append("--report")

            cmd.extend(["--pcpus", str(self.cores)])

            self.logSignal.emit(f"Running command: {' '.join(cmd)}\n")

            self.process = subprocess.Popen(
                cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
            )

            for line in self.process.stdout:
                self.logSignal.emit(line)
            for line in self.process.stderr:
                self.logSignal.emit(f"ERROR: {line.strip()}")

            self.process.wait()

            if self.process.returncode == 0:
                self.finishedSignal.emit(True)
            else:
                self.logSignal.emit(f"Pipeline finished with errors. Return code: {self.process.returncode}\n")
                self.finishedSignal.emit(False)

        except FileNotFoundError:
            self.logSignal.emit("Error: Nextflow executable not found. Ensure it is installed and in PATH.\n")
            self.finishedSignal.emit(False)
        except Exception as e:
            self.logSignal.emit(f"Unexpected error: {str(e)}\n")
            self.finishedSignal.emit(False)

    def stop(self):
        if self.process and self.process.poll() is None:
            self.process.terminate()
        self.wait()


class fMFullParamsPage(QWidget):
    def __init__(self, mainWindow):
        super().__init__()
        self.mainWindow = mainWindow
        self.setupUi()
        self.setStyleSheet(self.getStyles())

    def getStyles(self):
        return """
        /* Base styles */
        QWidget {
            background-color: #f5f7fa;
            font-family: 'Segoe UI', Arial, sans-serif;
        }

        /* Group boxes */
        QGroupBox {
            border: 1px solid #cbd5e0;
            border-radius: 6px;
            margin-top: 10px;
            padding-top: 15px;
            font-weight: bold;
            color: #2d3748;
        }

        QGroupBox::title {
            subcontrol-origin: margin;
            left: 10px;
            padding: 0 3px;
        }

        /* Labels */
        QLabel {
            font-size: 14px;
            color: #4a5568;
        }

        /* Line edits */
        QLineEdit {
            border: 1px solid #cbd5e0;
            border-radius: 4px;
            padding: 6px;
            font-size: 14px;
            background-color: white;
        }

        /* Buttons */
        QPushButton {
            padding: 8px 16px;
            border-radius: 4px;
            font-weight: 500;
            font-size: 14px;
        }

        #runButton {
            background-color: #48bb78;
            color: white;
        }

        #runButton:hover {
            background-color: #38a169;
        }

        #abortButton {
            background-color: #f56565;
            color: white;
        }

        #abortButton:hover {
            background-color: #e53e3e;
        }

        #backButton {
            background-color: #a0aec0;
            color: white;
        }

        #backButton:hover {
            background-color: #718096;
        }

        /* Browse buttons */
        #browseButton {
            background-color: #4299e1;
            color: white;
        }

        #browseButton:hover {
            background-color: #3182ce;
        }

        /* Group box buttons */
        QGroupBox QPushButton {
            background-color: #e2e8f0;
            color: #2d3748;
            border: 1px solid #cbd5e0;
        }

        QGroupBox QPushButton:hover {
            background-color: #cbd5e0;
        }

        /* Combo boxes */
        QComboBox {
            border: 1px solid #cbd5e0;
            border-radius: 4px;
            padding: 6px;
            font-size: 14px;
            background-color: #ffefe9;
            color: black; 
        }

        /* Text edit (log output) */
        QTextEdit {
            background-color: #1a202c;
            color: #e2e8f0;
            border: 1px solid #2d3748;
            border-radius: 4px;
            padding: 10px;
            font-family: 'Courier New', monospace;
            font-size: 12px;
        }

        /* Scroll bars */
        QScrollBar:vertical {
            border: none;
            background: #2d3748;
            width: 10px;
        }

        QScrollBar::handle:vertical {
            background: #ADD8E6; /* 80 = ~50% opacity */
            min-height: 20px;
            border-radius: 4px;
        }
        """

    def setupUi(self):
        sidebarLayout = QVBoxLayout()

        # Workflow selection
        self.workflowLabel = QLabel("Workflow:")
        sidebarLayout.addWidget(self.workflowLabel)
        self.workflowInput = QLineEdit()
        self.workflowInput.setPlaceholderText("Workflow Path File")
        sidebarLayout.addWidget(self.workflowInput)
        self.workflowButton = QPushButton("Browse Workflow")
        self.workflowButton.setObjectName("browseButton")
        self.workflowButton.clicked.connect(self.selectWorkflow)
        sidebarLayout.addWidget(self.workflowButton)

        # CPU cores slider
        self.cpuCoresLabel = QLabel(f"CPU Cores: 2 (max: {os.cpu_count() or 2})")
        self.cpuCoresLabel.setAlignment(Qt.AlignCenter)
        sidebarLayout.addWidget(self.cpuCoresLabel)
        self.cpuCoresSlider = QSlider(Qt.Horizontal)
        self.cpuCoresSlider.setMinimum(2)
        self.cpuCoresSlider.setMaximum(os.cpu_count() or 2)
        self.cpuCoresSlider.setValue(2)
        self.cpuCoresSlider.setTickPosition(QSlider.TicksBelow)
        self.cpuCoresSlider.setTickInterval(1)
        self.cpuCoresSlider.valueChanged.connect(self.updateCpuCoresLabel)
        sidebarLayout.addWidget(self.cpuCoresSlider)

        # Input file selection
        self.inputLabel = QLabel("Input File:")
        sidebarLayout.addWidget(self.inputLabel)
        self.inputInput = QLineEdit()
        self.inputInput.setPlaceholderText("path/to/input_file")
        sidebarLayout.addWidget(self.inputInput)
        self.inputButton = QPushButton("Browse Input")
        self.inputButton.setObjectName("browseButton")
        self.inputButton.clicked.connect(self.selectInputFile)
        sidebarLayout.addWidget(self.inputButton)

        # Reference file selection
        self.referenceLabel = QLabel("Reference File (optional):")
        sidebarLayout.addWidget(self.referenceLabel)
        self.referenceInput = QLineEdit()
        self.referenceInput.setPlaceholderText("path/to/reference.fasta")
        sidebarLayout.addWidget(self.referenceInput)
        self.referenceButton = QPushButton("Browse Reference")
        self.referenceButton.setObjectName("browseButton")
        self.referenceButton.clicked.connect(self.selectReferenceFile)
        sidebarLayout.addWidget(self.referenceButton)

        # Aligner selection
        self.alignerGroup = QGroupBox("Aligner")
        self.alignerLayout = QHBoxLayout()

        self.alignerDefault = QRadioButton("Default")
        self.alignerDefault.setChecked(True)
        self.alignerBwaMem2 = QRadioButton("bwamem2")

        self.alignerLayout.addWidget(self.alignerDefault)
        self.alignerLayout.addWidget(self.alignerBwaMem2)
        self.alignerGroup.setLayout(self.alignerLayout)
        sidebarLayout.addWidget(self.alignerGroup)
        # Metrics toggle
        self.metricsGroup = QGroupBox("Metrics")
        self.metricsLayout = QHBoxLayout()

        self.metricsEnable = QRadioButton("Enable")
        self.metricsEnable.setChecked(True)
        self.metricsDisable = QRadioButton("Disable")

        self.metricsLayout.addWidget(self.metricsEnable)
        self.metricsLayout.addWidget(self.metricsDisable)
        self.metricsGroup.setLayout(self.metricsLayout)
        sidebarLayout.addWidget(self.metricsGroup)

        # Profiles group
        self.profileGroup = QGroupBox("Profiles")
        self.profileLayout = QVBoxLayout()

        self.standardProfile = QCheckBox("standard")
        self.standardProfile.setChecked(True)
        self.condaProfile = QCheckBox("conda")
        self.mambaProfile = QCheckBox("mamba")
        self.dockerProfile = QCheckBox("docker")
        self.singularityProfile = QCheckBox("singularity")
        self.testProfile = QCheckBox("test")

        self.profileLayout.addWidget(self.standardProfile)
        self.profileLayout.addWidget(self.condaProfile)
        self.profileLayout.addWidget(self.mambaProfile)
        self.profileLayout.addWidget(self.dockerProfile)
        self.profileLayout.addWidget(self.singularityProfile)
        self.profileLayout.addWidget(self.testProfile)

        # Connect signals to enforce profile selection rules
        self.standardProfile.stateChanged.connect(self.updateProfileSelection)
        self.condaProfile.stateChanged.connect(self.updateProfileSelection)
        self.mambaProfile.stateChanged.connect(self.updateProfileSelection)
        self.dockerProfile.stateChanged.connect(self.updateProfileSelection)
        self.singularityProfile.stateChanged.connect(self.updateProfileSelection)
        self.testProfile.stateChanged.connect(self.updateProfileSelection)

        self.profileGroup.setLayout(self.profileLayout)
        sidebarLayout.addWidget(self.profileGroup)

        # In setupUi, modify the BQSR group creation:
        self.bqsrGroup = QGroupBox("Base Quality Score Recalibration (BQSR)")
        self.bqsrLayout = QVBoxLayout()

        # Create a horizontal layout for the radio buttons
        bqsrRadioLayout = QHBoxLayout()
        self.bqsrEnable = QRadioButton("Enable")
        self.bqsrDisable = QRadioButton("Disable")
        self.bqsrDisable.setChecked(True)  # Default to disabled
        bqsrRadioLayout.addWidget(self.bqsrEnable)
        bqsrRadioLayout.addWidget(self.bqsrDisable)
        self.bqsrLayout.addLayout(bqsrRadioLayout)

        # Rest of the BQSR group setup remains the same
        self.bqsrEnable.toggled.connect(self.toggleBqsrOptions)
        self.createVcfSelectionGroup()
        self.bqsrLayout.addWidget(self.vcfSelectionGroup)
        self.bqsrGroup.setLayout(self.bqsrLayout)
        sidebarLayout.addWidget(self.bqsrGroup)

        # Variant Calling Mode group (new section)
        self.variantModeGroup = QGroupBox("Variant Calling Mode")
        self.variantModeLayout = QVBoxLayout()

        self.variantModeLabel = QLabel("Select variant calling mode:")
        self.variantModeCombo = QComboBox()
        self.variantModeCombo.addItems(["defaults", "cohort"])

        self.variantModeLayout.addWidget(self.variantModeLabel)
        self.variantModeLayout.addWidget(self.variantModeCombo)
        self.variantModeGroup.setLayout(self.variantModeLayout)
        sidebarLayout.addWidget(self.variantModeGroup)
        # Control buttons
        sidebarLayout.addStretch(1)
        self.runButton = QPushButton("Run Pipeline")
        self.runButton.setObjectName("runButton")
        self.runButton.clicked.connect(self.runPipeline)
        sidebarLayout.addWidget(self.runButton)

        self.abortButton = QPushButton("Abort Pipeline")
        self.abortButton.setObjectName("abortButton")
        self.abortButton.clicked.connect(self.abortPipeline)
        self.abortButton.setEnabled(False)
        sidebarLayout.addWidget(self.abortButton)

        backButton = QPushButton("Back to Welcome")
        backButton.setObjectName("backButton")
        backButton.clicked.connect(self.mainWindow.showWelcomePage)
        sidebarLayout.addWidget(backButton)

        # Log output
        self.logOutput = QTextEdit()
        self.logOutput.setReadOnly(True)
        self.logOutput.setFontFamily("Courier")
        self.logOutput.setLineWrapMode(QTextEdit.NoWrap)

        # Main layout
        sidebarWidget = QWidget()
        sidebarWidget.setLayout(sidebarLayout)

        scrollArea = QScrollArea()
        scrollArea.setWidgetResizable(True)
        scrollArea.setWidget(sidebarWidget)
        scrollArea.setVerticalScrollBarPolicy(Qt.ScrollBarAsNeeded)
        scrollArea.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        scrollArea.setMinimumWidth(220)
        sidebarWidget.setMinimumWidth(200)

        mainLayout = QHBoxLayout()
        mainLayout.addWidget(scrollArea, 1)
        mainLayout.addWidget(self.logOutput, 8)

        self.setLayout(mainLayout)

    def createVcfSelectionGroup(self):
        """Create the VCF source selection widgets"""
        self.vcfSelectionGroup = QGroupBox("VCF Selection (for BQSR)")
        self.vcfSelectionLayout = QVBoxLayout()
        self.vcfSelectionGroup.setVisible(False)

        # Radio buttons
        radioLayout = QHBoxLayout()
        self.vcfOptionGroup = QButtonGroup()

        self.localVcfRadio = QRadioButton("Local VCF Files")
        self.bundleVcfRadio = QRadioButton("Use Bundle VCFs")

        self.vcfOptionGroup.addButton(self.localVcfRadio)
        self.vcfOptionGroup.addButton(self.bundleVcfRadio)

        radioLayout.addWidget(self.localVcfRadio)
        radioLayout.addWidget(self.bundleVcfRadio)
        radioLayout.addStretch()

        self.vcfSelectionLayout.addLayout(radioLayout)

        # Local VCF widgets
        self.localVcfWidget = QWidget()
        self.localVcfLayout = QVBoxLayout()

        # VCF 1
        self.vcf1Layout = QHBoxLayout()
        self.vcf1Label = QLabel("VCF 1:")
        self.vcf1Input = QLineEdit()
        self.vcf1Button = QPushButton("📂")
        self.vcf1Button.clicked.connect(lambda: self.browseVcfFile(self.vcf1Input))
        self.vcf1Layout.addWidget(self.vcf1Label)
        self.vcf1Layout.addWidget(self.vcf1Input)
        self.vcf1Layout.addWidget(self.vcf1Button)

        # VCF 2
        self.vcf2Layout = QHBoxLayout()
        self.vcf2Label = QLabel("VCF 2:")
        self.vcf2Input = QLineEdit()
        self.vcf2Button = QPushButton("📂️")
        self.vcf2Button.clicked.connect(lambda: self.browseVcfFile(self.vcf2Input))
        self.vcf2Layout.addWidget(self.vcf2Label)
        self.vcf2Layout.addWidget(self.vcf2Input)
        self.vcf2Layout.addWidget(self.vcf2Button)

        self.localVcfLayout.addLayout(self.vcf1Layout)
        self.localVcfLayout.addLayout(self.vcf2Layout)
        self.localVcfWidget.setLayout(self.localVcfLayout)

        # Bundle VCF widgets
        self.bundleVcfWidget = QWidget()
        self.bundleVcfLayout = QVBoxLayout()

        self.referenceLabel = QLabel("Reference Genome:")
        self.referenceCombo = QComboBox()
        self.referenceCombo.addItems(["GRCh37", "GRCh38", "hg19", "hg38"])

        # First bundle VCF
        self.bundle1Label = QLabel("Primary VCF Bundle:")
        self.bundle1Combo = QComboBox()

        # Second bundle VCF
        self.bundle2Label = QLabel("Secondary VCF Bundle (optional):")
        self.bundle2Combo = QComboBox()

        self.bundleVcfLayout.addWidget(self.referenceLabel)
        self.bundleVcfLayout.addWidget(self.referenceCombo)
        self.bundleVcfLayout.addWidget(self.bundle1Label)
        self.bundleVcfLayout.addWidget(self.bundle1Combo)
        self.bundleVcfLayout.addWidget(self.bundle2Label)
        self.bundleVcfLayout.addWidget(self.bundle2Combo)
        self.bundleVcfWidget.setLayout(self.bundleVcfLayout)

        # Add to main layout
        self.vcfSelectionLayout.addWidget(self.localVcfWidget)
        self.vcfSelectionLayout.addWidget(self.bundleVcfWidget)
        self.vcfSelectionGroup.setLayout(self.vcfSelectionLayout)

        # Connect signals
        self.localVcfRadio.toggled.connect(self.toggleVcfSource)
        self.bundleVcfRadio.toggled.connect(self.toggleVcfSource)
        self.referenceCombo.currentTextChanged.connect(self.updateBundleOptions)

        # Set default
        self.localVcfRadio.setChecked(True)
        self.bundleVcfWidget.setVisible(False)
        self.updateBundleOptions()

    def toggleVcfSource(self, checked):
        """Toggle between local and bundle VCF sources"""
        # Determine which radio button was toggled
        if self.sender() == self.localVcfRadio and checked:
            self.localVcfWidget.setVisible(True)
            self.bundleVcfWidget.setVisible(False)
            # Enable/disable controls based on BQSR radio button
            if self.bqsrEnable.isChecked():  # Changed from enableBqsrCheck
                self.vcf1Input.setEnabled(True)
                self.vcf1Button.setEnabled(True)
                self.vcf2Input.setEnabled(True)
                self.vcf2Button.setEnabled(True)
                self.referenceCombo.setEnabled(False)
                self.bundle1Combo.setEnabled(False)
                self.bundle2Combo.setEnabled(False)
        elif self.sender() == self.bundleVcfRadio and checked:
            self.localVcfWidget.setVisible(False)
            self.bundleVcfWidget.setVisible(True)
            # Enable/disable controls based on BQSR radio button
            if self.bqsrEnable.isChecked():  # Changed from enableBqsrCheck
                self.vcf1Input.setEnabled(False)
                self.vcf1Button.setEnabled(False)
                self.vcf2Input.setEnabled(False)
                self.vcf2Button.setEnabled(False)
                self.referenceCombo.setEnabled(True)
                self.bundle1Combo.setEnabled(True)
                self.bundle2Combo.setEnabled(True)

    def updateBundleOptions(self):
        """Update the bundle options with exact parameter names"""
        reference = self.referenceCombo.currentText()
        self.bundle1Combo.clear()
        self.bundle2Combo.clear()

        # Mapping of reference genome to available bundles
        bundle_map = {
            'GRCh38': [
                'GRCh38.omni',
                'GRCh38.ph1.snp',
                'GRCh38.mills1000',
                'GRCh38.dbsnp138',
                'GRCh38.dbsnp144',
                'GRCh38.dbsnp146',
                'GRCh38.hapmap3.3'
            ],
            'GRCh37': [
                'GRCh37.omni',
                'GRCh37.ph1.ind',
                'GRCh37.ph1.snp',
                'GRCh37.ph3',
                'GRCh37.mills1000',
                'GRCh37.dbsnp138',
                'GRCh37.hapmap3.3'
            ],
            'hg19': [
                'h19.omni',
                'h19.ph1.ind',
                'h19.ph1.snp',
                'h19.dbsnp138',
                'h19.hapmap3.3'
            ],
            'hg38': [
                'hg38.omni',
                'hg38.ph1.snp',
                'hg38.mills1000',
                'hg38.dbsnp138',
                'hg38.dbsnp144',
                'hg38.dbsnp146',
                'hg38.hapmap3.3'
            ]
        }

        if reference in bundle_map:
            for param_name in bundle_map[reference]:
                display_name = param_name.split('.', 1)[1]
                display_name = display_name.replace('ph1', 'Phase1').replace('ph3', 'Phase3') \
                    .replace('mills', 'Mills ').replace('dbsnp', 'dbSNP ') \
                    .replace('hapmap', 'HapMap ').replace('omni', 'Omni') \
                    .replace('ind', 'Indels').replace('snp', 'SNPs')
                self.bundle1Combo.addItem(display_name, userData=param_name)
                self.bundle2Combo.addItem(display_name, userData=param_name)

    def updateProfileSelection(self):
        """Enforce profile selection rules"""
        if self.testProfile.isChecked():
            self.standardProfile.setChecked(False)
            self.condaProfile.setChecked(False)
            self.mambaProfile.setChecked(False)
            self.dockerProfile.setChecked(False)
            self.singularityProfile.setChecked(False)

        exclusive_profiles = [self.condaProfile, self.mambaProfile,
                              self.dockerProfile, self.singularityProfile]

        sender = self.sender()
        if sender in exclusive_profiles and sender.isChecked():
            for profile in exclusive_profiles:
                if profile != sender and profile.isChecked():
                    profile.setChecked(False)

    def toggleBqsrOptions(self, checked):
        """Enable/disable BQSR options based on radio button state"""
        enabled = self.bqsrEnable.isChecked()  # Changed from just using 'checked'
        self.vcfSelectionGroup.setVisible(enabled)

        if enabled:
            if self.localVcfRadio.isChecked():
                self.vcf1Input.setEnabled(True)
                self.vcf1Button.setEnabled(True)
                self.vcf2Input.setEnabled(True)
                self.vcf2Button.setEnabled(True)
            else:
                self.referenceCombo.setEnabled(True)
                self.bundle1Combo.setEnabled(True)
                self.bundle2Combo.setEnabled(True)
        else:
            self.vcf1Input.setEnabled(False)
            self.vcf1Button.setEnabled(False)
            self.vcf2Input.setEnabled(False)
            self.vcf2Button.setEnabled(False)
            self.referenceCombo.setEnabled(False)
            self.bundle1Combo.setEnabled(False)
            self.bundle2Combo.setEnabled(False)

    def selectWorkflow(self):
        filePath, _ = QFileDialog.getOpenFileName(self, "Select Workflow File", "", "Nextflow Files (*.nf)")
        if filePath:
            self.workflowInput.setText(filePath)

    def selectInputFile(self):
        filePath, _ = QFileDialog.getOpenFileName(self, "Select Input File", "", "All Files (*)")
        if filePath:
            self.inputInput.setText(filePath)

    def selectReferenceFile(self):
        filePath, _ = QFileDialog.getOpenFileName(self, "Select Reference File", "", "FASTA Files (*.fa *.fasta *.gz)")
        if filePath:
            self.referenceInput.setText(filePath)

    def browseVcfFile(self, lineEdit):
        filePath, _ = QFileDialog.getOpenFileName(self, "Select VCF File", "", "VCF Files (*.vcf *.vcf.gz)")
        if filePath:
            lineEdit.setText(filePath)

    def updateCpuCoresLabel(self, value):
        self.cpuCoresLabel.setText(f"CPU Cores: {value} (max: {os.cpu_count() or 2})")

    def runPipeline(self):
        workflow = self.workflowInput.text()
        input_file = self.inputInput.text()
        reference_file = self.referenceInput.text() if self.referenceInput.text() else None
        selected_cores = self.cpuCoresSlider.value()
        aligner = "bwamem2" if self.alignerBwaMem2.isChecked() else "default"
        enable_metrics = self.metricsEnable.isChecked()
        enable_bqsr = self.bqsrEnable.isChecked()

        # Get selected profiles
        profiles = []
        if self.standardProfile.isChecked():
            profiles.append("standard")
        if self.condaProfile.isChecked():
            profiles.append("conda")
        if self.mambaProfile.isChecked():
            profiles.append("mamba")
        if self.dockerProfile.isChecked():
            profiles.append("docker")
        if self.singularityProfile.isChecked():
            profiles.append("singularity")
        if self.testProfile.isChecked():
            profiles.append("test")

        # Get BQSR options
        enable_bqsr = self.bqsrEnable.isChecked()  # Use the radio button instead

        vcf_files = []
        bundleVcf = []

        if enable_bqsr:
            if self.localVcfRadio.isChecked():
                if self.vcf1Input.text():
                    vcf_files.append(self.vcf1Input.text())
                if self.vcf2Input.text():
                    vcf_files.append(self.vcf2Input.text())
            else:
                if self.bundle1Combo.currentData():
                    bundleVcf.append(self.bundle1Combo.currentData())
                if self.bundle2Combo.currentData() and self.bundle2Combo.currentData() != self.bundle1Combo.currentData():
                    bundleVcf.append(self.bundle2Combo.currentData())

        # Get variant calling mode
        variantMode = self.variantModeCombo.currentText()

        # Validate inputs
        if not workflow:
            QMessageBox.critical(self, "Error", "Please select a workflow file.")
            return

        if not input_file:
            QMessageBox.critical(self, "Error", "Please select an input file.")
            return

        if enable_bqsr:
            if self.localVcfRadio.isChecked() and not vcf_files:
                QMessageBox.critical(self, "Error", "Please select at least one VCF file for BQSR.")
                return
            elif self.bundleVcfRadio.isChecked() and not bundleVcf:
                QMessageBox.critical(self, "Error", "Please select at least one VCF bundle for BQSR.")
                return

        self.logOutput.clear()
        self.logOutput.append("Starting pipeline...\n")

        self.runnerThread = PipelineRunnerThread(
            workflow=workflow,
            input_file=input_file,
            reference_file=reference_file,
            aligner=aligner,
            enable_metrics=enable_metrics,
            cores=selected_cores,
            profiles=profiles,
            enable_bqsr=enable_bqsr,
            vcf_files=vcf_files,
            bundleVcf=bundleVcf,
            variantMode=variantMode
        )
        self.runnerThread.logSignal.connect(self.logOutput.append)
        self.runnerThread.finishedSignal.connect(self.pipelineFinished)
        self.runnerThread.start()

        self.runButton.setEnabled(False)
        self.abortButton.setEnabled(True)

    def abortPipeline(self):
        if hasattr(self, 'runnerThread') and self.runnerThread is not None:
            self.runnerThread.stop()
            self.runnerThread = None
            self.runButton.setEnabled(True)
            self.abortButton.setEnabled(False)
        else:
            QMessageBox.warning(self, "Warning", "No pipeline is currently running to abort.")

    def pipelineFinished(self, success):
        self.runButton.setEnabled(True)
        self.abortButton.setEnabled(False)
        if success:
            QMessageBox.information(self, "Success", "Pipeline completed successfully!")
            self.logOutput.append("\nPipeline finished successfully!")
        else:
            QMessageBox.critical(self, "Error", "Pipeline failed! Check the log for details.")
            self.logOutput.append("\nPipeline failed.")

__all__ = ['fMFullParamsPage']

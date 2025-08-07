import os
import subprocess
from PyQt5.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel, QLineEdit,
    QPushButton, QComboBox, QTextEdit, QMessageBox, QFileDialog, QSlider, QGroupBox, QRadioButton, QButtonGroup,
    QCheckBox, QScrollArea
)
from PyQt5.QtCore import QThread, pyqtSignal, Qt


class FullParamsRunnerThread(QThread):
    logSignal = pyqtSignal(str)
    finishedSignal = pyqtSignal(bool)

    def __init__(self, workflow, selectedExec, profile, generateOption, csvFile=None, csvForRawQc=None,
                 csvForTrimming=None, trimmer=None, csvForAssembly=None,csvForBqsr=None, referenceFile=None, aligner=None, cores=2, vcf1=None, vcf2=None,  bundleVcf=None, csvForVarC=None, csvForAnn=None,species=None, assembly=None,
                 cachetype=None, cacheversion=None):
        """ Initialize the pipeline runner with execution parameters"""
        super().__init__()
        """ Pipeline Configuration Parameters """
        self.workflow = workflow            # Path to Nextflow workflow file
        self.cores = cores                  # Number of CPU cores to use for processing
        self.selectedExec = selectedExec      # Selected execution operation
        self.generateOption = generateOption  # Pipeline generation option

        """ CSV File Inputs for Different Pipeline Stages"""
        self.csvFile = csvFile          # Primary CSV input file
        self.csvForRawQc = csvForRawQc  # CSV for raw quality control
        self.csvForTrimming = csvForTrimming  # CSV for trimming stage
        self.csvForAssembly = csvForAssembly  # CSV for assembly stage
        self.csvForBqsr = csvForBqsr  # CSV for Base Quality Score Recalibration
        self.csvForVarC = csvForVarC  # CSV for variant calling
        self.csvForAnn = csvForAnn    # CSV for annotation stage

        """ Reference Data Inputs """
        self.referenceFile = referenceFile  # Reference genome file
        self.bundleVcf = bundleVcf          # Bundle VCF file for analysis
        self.vcf1Input = vcf1  # First VCF input file
        self.vcf2Input = vcf2  # Second VCF input file

        """ Tool Selection Parameters """
        self.aligner = aligner  # Selected alignment tool
        self.trimmer = trimmer  # Selected trimming tool

        """ Execution Control """
        self.process = None     # Will hold the subprocess reference during execution

        """ Pipeline Configuration Profiles """
        self.profile = profile  # Nextflow execution profile(s) (comma-separated)

        """ Parameters For Annotation """
        self.species = species      # Target species for analysis
        self.assembly = assembly    # Genome assembly version
        self.cachetype = cachetype  # Cache type for annotation databases
        self.cacheversion = cacheversion  # Version of annotation cache

    def run(self):
        """Main execution method for the Nextflow pipeline runner thread."""
        try:
            # Validate workflow file exists
            if not os.path.exists(self.workflow):
                self.logSignal.emit(f"Error: Workflow file '{self.workflow}' does not exist.\n")
                self.finishedSignal.emit(False)
                return

            # Base Nextflow command components
            cmd = ["nextflow", "run", self.workflow, "-profile", self.profile, "--cpus", str(self.cores), "--stepmode"]

            # Check if test profile is selected (simplified execution)
            if "test" in self.profile.split(","):
                cmd.extend(["--exec", self.selectedExec])
            else:
                # Handle different execution modes with their specific parameters

                # CSV Generation Mode
                if self.selectedExec == "Generate CSV" and self.csvFile:
                    cmd.extend(["--generate", "CSV", "--basedon", self.csvFile])

                # Raw Quality Control Mode
                elif self.selectedExec == "rawqc" and self.csvForRawQc:
                    cmd.extend(["--exec", self.selectedExec, "--rawreads", self.csvForRawQc])

                # Read Trimming Mode
                elif self.selectedExec == "trim" and self.csvForTrimming and self.trimmer:
                    cmd.extend(["--exec", self.selectedExec, "--tobetrimmed", self.csvForTrimming, f"--{self.trimmer}"])

                # Reference Indexing Mode
                elif self.selectedExec == "refidx":
                    if self.referenceFile:
                        cmd.extend(["--exec", self.selectedExec, "--reference", self.referenceFile])
                        if self.aligner == "bwamem2":  # Special case for BWA-MEM2 aligner
                            cmd.extend(["--aligner", "bwamem2"])

                # Sequence Alignment Mode
                elif self.selectedExec == "align" and self.csvForAssembly:
                    cmd.extend(["--exec", self.selectedExec, "--reference", self.referenceFile, "--tobealigned",
                                self.csvForAssembly])
                    if self.aligner == "bwamem2":
                        cmd.extend(["--aligner", "bwamem2"])

                # Base Quality Score Recalibration Mode
                elif self.selectedExec == "bqsr" and self.csvForBqsr:
                    cmd.extend(
                        ["--exec", self.selectedExec, "--reference", self.referenceFile, "--bam", self.csvForBqsr])

                    # Handle VCF inputs for BQSR
                    if self.bundleVcf:  # Using pre-bundled VCFs
                        if len(self.bundleVcf) > 0:  # First VCF if available
                            cmd.extend(["--ivcf1", self.bundleVcf[0]])
                            if len(self.bundleVcf) > 1:  # Second VCF if available
                                cmd.extend(["--ivcf2", self.bundleVcf[1]])
                    else:  # Using local VCF files
                        if self.vcf1Input:
                            cmd.extend(["--knownsite1", self.vcf1Input])
                            if self.vcf2Input:
                                cmd.extend(["--knownsite2", self.vcf2Input])

                # Variant Calling Mode
                elif self.selectedExec == "callsnp":
                    cmd.extend(["--exec", self.selectedExec,
                                "--reference", self.referenceFile,
                                "--tovarcall", self.csvForVarC])

                    if self.generateOption and self.generateOption != "Defaults":
                        cmd.extend(["--mode", self.generateOption])

                # VEP Cache Setup Mode
                elif self.selectedExec == "vepcache":
                    cmd.extend(["--exec", self.selectedExec,
                                "--species", self.species,
                                "--assembly", self.assembly,
                                "--cacheversion", self.cacheversion])
                    if self.cachetype != "vep":  # Only specify if not default VEP cache
                        cmd.extend(["--cachetype", self.cachetype])

                # Variant Annotation Mode
                elif self.selectedExec == "vepannotate":
                    cmd.extend(["--exec", self.selectedExec,
                                "--reference", self.referenceFile,
                                "--toannotate", self.csvForAnn,
                                "--species", self.species,
                                "--assembly", self.assembly,
                                "--cacheversion", self.cacheversion])
                    if self.cachetype != "vep":
                        cmd.extend(["--cachetype", self.cachetype])
                else:
                    # Default execution with no additional parameters
                    cmd.extend(["--exec", self.selectedExec])

            # Log the full command being executed
            self.logSignal.emit(f"Running command: {' '.join(cmd)}\n")

            # Launch the Nextflow process
            self.process = subprocess.Popen(
                cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
            )

            # Stream output to GUI in real-time
            for line in self.process.stdout:
                self.logSignal.emit(line)
            for line in self.process.stderr:
                self.logSignal.emit(f"ERROR: {line.strip()}")

            # Wait for process completion
            self.process.wait()

            # Handle process completion status
            if self.process.returncode == 0:
                self.finishedSignal.emit(True)  # Success signal
            else:
                self.logSignal.emit(f"Pipeline finished with errors. Return code: {self.process.returncode}\n")
                self.finishedSignal.emit(False)  # Failure signal

        # Error handling
        except FileNotFoundError:
            self.logSignal.emit("Error: Nextflow executable not found. Ensure it is installed and in PATH.\n")
            self.finishedSignal.emit(False)
        except Exception as e:
            self.logSignal.emit(f"Unexpected error: {str(e)}\n")
            self.finishedSignal.emit(False)

    def stop(self):
        """Stop the pipeline execution."""
        self._is_running = False
        if self.process and self.process.poll() is None:
            self.process.terminate()
        self.wait()  # Wait for the thread to finish


class sMFullParamsPage(QWidget):
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

        """ Create and configure workflow selection UI elements """

        self.workflowLabel = QLabel("Workflow:")        # Label for workflow input field
        sidebarLayout.addWidget(self.workflowLabel)     # Add label to sidebar layout

        # Create text input field for workflow path
        self.workflowInput = QLineEdit()                                # Line edit widget for displaying/editing workflow path
        self.workflowInput.setPlaceholderText("Workflow Path File")     # Hint text
        sidebarLayout.addWidget(self.workflowInput)                     # Add input field to layout

        # Create browse button for workflow selection
        self.workflowButton = QPushButton("Browse Workflow")    # Button with descriptive text
        self.workflowButton.setObjectName("browseButton")       # Set object name for CSS styling
        self.workflowButton.setToolTip("Select a Nextflow workflow file")   # Help tooltip
        self.workflowButton.clicked.connect(self.selectWorkflow)            # Connect click to handler
        sidebarLayout.addWidget(self.workflowButton)                        # Add button to layout


        """ Creates a slider control for selecting the number of CPU cores to use for processing """

        # Create and configure the CPU cores label
        self.cpuCoresLabel = QLabel(f"CPU Cores: 2 (max: {os.cpu_count() or 2})")
        self.cpuCoresLabel.setAlignment(Qt.AlignCenter)     # Center-align the text
        sidebarLayout.addWidget(self.cpuCoresLabel)         # Add to sidebar layout

        # Create horizontal slider for core selection
        self.cpuCoresSlider = QSlider(Qt.Horizontal)        # Horizontal orientation slider
        self.cpuCoresSlider.setMinimum(2)                   # Minimum 2 cores (prevent system freeze with 1 core)
        self.cpuCoresSlider.setMaximum(os.cpu_count() or 2) # Max available cores, fallback to 2 if detection fails
        self.cpuCoresSlider.setValue(2)                     # Default to 2 cores
        self.cpuCoresSlider.setTickPosition(QSlider.TicksBelow)             # Show ticks below slider
        self.cpuCoresSlider.setTickInterval(1)                              # Show ticks for every integer value
        self.cpuCoresSlider.valueChanged.connect(self.updateCpuCoresLabel)  # Connect value change to label update
        sidebarLayout.addWidget(self.cpuCoresSlider)                        # Add slider to layout

        # Create execution option label
        self.optionLabel = QLabel("Exec Option:")  # Label for execution mode dropdown
        sidebarLayout.addWidget(self.optionLabel)  # Add label to layout
        # Create and configure execution mode dropdown
        self.optionDropdown = QComboBox()   # Dropdown selector for pipeline operations
        self.optionDropdown.addItems([      # Add available pipeline operations:
            "Generate CSV",     # CSV generation mode
            "rawqc",            # Raw quality control
            "trim",             # Read trimming
            "refidx",           # Reference indexing
            "align",            # Sequence alignment
            "bqsr",             # Base quality score recalibration
            "callsnp",          # Variant calling
            "vepcache",         # VEP cache setup
            "vepannotate",      # Variant annotation
            "params",           # Parmeters information
            "help"              # Help information
        ])
        self.optionDropdown.currentTextChanged.connect(self.toggleOptions)
        sidebarLayout.addWidget(self.optionDropdown)


        """ Trimmer Selection Widgets For Selecting Read Trimming Tools """

        self.trimmerLabel = QLabel("Trimmer:")      # Label for trimmer selection dropdown
        sidebarLayout.addWidget(self.trimmerLabel)  # Add label to sidebar layout
        self.trimmerDropdown = QComboBox()          # Dropdown for selecting trimming tools
        self.trimmerDropdown.addItems([
            "trimmomatic",  # Flexible read trimming tool
            "fastp",        # Fast all-in-one preprocessor
            "bbduk"         # BBTools suite trimmer
        ])
        sidebarLayout.addWidget(self.trimmerDropdown)  # Add dropdown to layout

        """ CSV FILE SELECTION WIDGETS """

        # Main CSV Input for Initialization
        # -------------------------------
        self.csvLabel = QLabel("CSV File:")
        sidebarLayout.addWidget(self.csvLabel)
        self.csvInput = QLineEdit()
        self.csvInput.setPlaceholderText("path/to/samples.csv")
        self.csvInput.setToolTip("Main sample metadata CSV file")
        sidebarLayout.addWidget(self.csvInput)
        self.csvButton = QPushButton("Browse CSV")
        self.csvButton.setObjectName("browseButton")
        self.csvButton.setToolTip("Select main sample CSV file")
        self.csvButton.clicked.connect(self.selectCsvFile)
        sidebarLayout.addWidget(self.csvButton)

        # CSV for Raw Quality Control
        self.csvForRawQcLabel = QLabel("CSV for Raw QC:")
        sidebarLayout.addWidget(self.csvForRawQcLabel)
        self.csvForRawQcInput = QLineEdit()
        self.csvForRawQcInput.setPlaceholderText("path/to/raw_qc_samples.csv")
        self.csvForRawQcInput.setToolTip("CSV for raw read quality control")
        sidebarLayout.addWidget(self.csvForRawQcInput)
        self.csvForRawQcButton = QPushButton("Browse CSV")
        self.csvForRawQcButton.setObjectName("browseButton")
        self.csvForRawQcButton.setToolTip("Select CSV for raw QC analysis")
        self.csvForRawQcButton.clicked.connect(self.selectCsvForRawQcFile)
        sidebarLayout.addWidget(self.csvForRawQcButton)

        # CSV for Trimming Stage
        self.csvForTrimmingLabel = QLabel("CSV for Trimming:")
        sidebarLayout.addWidget(self.csvForTrimmingLabel)
        self.csvForTrimmingInput = QLineEdit()
        self.csvForTrimmingInput.setPlaceholderText("path/to/trimming_samples.csv")
        self.csvForTrimmingInput.setToolTip("CSV for read trimming samples")
        sidebarLayout.addWidget(self.csvForTrimmingInput)
        self.csvForTrimmingButton = QPushButton("Browse CSV")
        self.csvForTrimmingButton.setObjectName("browseButton")
        self.csvForTrimmingButton.setToolTip("Select CSV for read trimming")
        self.csvForTrimmingButton.clicked.connect(self.selectCsvForTrimmingFile)
        sidebarLayout.addWidget(self.csvForTrimmingButton)

        # CSV for Assembly Stage
        self.csvForAssemblyLabel = QLabel("CSV for Assembly:")
        sidebarLayout.addWidget(self.csvForAssemblyLabel)
        self.csvForAssemblyInput = QLineEdit()
        self.csvForAssemblyInput.setPlaceholderText("path/to/assembly_samples.csv")
        self.csvForAssemblyInput.setToolTip("CSV for assembly samples")
        sidebarLayout.addWidget(self.csvForAssemblyInput)
        self.csvForAssemblyButton = QPushButton("Browse CSV")
        self.csvForAssemblyButton.setObjectName("browseButton")
        self.csvForAssemblyButton.setToolTip("Select CSV for sequence assembly")
        self.csvForAssemblyButton.clicked.connect(self.selectCsvForAssemblyFile)
        sidebarLayout.addWidget(self.csvForAssemblyButton)

        # CSV for Base Quality Score Recalibration
        self.csvForBqsrLabel = QLabel("CSV for BQSR:")
        sidebarLayout.addWidget(self.csvForBqsrLabel)
        self.csvForBqsrInput = QLineEdit()
        self.csvForBqsrInput.setPlaceholderText("path/to/bqsr_samples.csv")
        self.csvForBqsrInput.setToolTip("CSV for BQSR analysis")
        sidebarLayout.addWidget(self.csvForBqsrInput)
        self.csvForBqsrButton = QPushButton("Browse CSV")
        self.csvForBqsrButton.setObjectName("browseButton")
        self.csvForBqsrButton.setToolTip("Select CSV for base quality recalibration")
        self.csvForBqsrButton.clicked.connect(self.selectCsvForBqsrFile)
        sidebarLayout.addWidget(self.csvForBqsrButton)

        # CSV for Variant Calling
        self.csvForVarCLabel = QLabel("CSV for Variant Calling:")
        sidebarLayout.addWidget(self.csvForVarCLabel)
        self.csvForVarCInput = QLineEdit()
        self.csvForVarCInput.setPlaceholderText("path/to/variant_samples.csv")
        self.csvForVarCInput.setToolTip("CSV for variant calling samples")
        sidebarLayout.addWidget(self.csvForVarCInput)
        self.csvForVarCButton = QPushButton("Browse CSV")
        self.csvForVarCButton.setObjectName("browseButton")
        self.csvForVarCButton.setToolTip("Select CSV for variant calling")
        self.csvForVarCButton.clicked.connect(self.selectcsvForVarCFile)
        sidebarLayout.addWidget(self.csvForVarCButton)

        # CSV for Annotation
        self.csvForAnnLabel = QLabel("CSV for Annotation:")
        sidebarLayout.addWidget(self.csvForAnnLabel)
        self.csvForAnnInput = QLineEdit()
        self.csvForAnnInput.setPlaceholderText("path/to/annotation_samples.csv")
        self.csvForAnnInput.setToolTip("CSV for variant annotation")
        sidebarLayout.addWidget(self.csvForAnnInput)
        self.csvForAnnButton = QPushButton("Browse CSV")
        self.csvForAnnButton.setObjectName("browseButton")
        self.csvForAnnButton.setToolTip("Select CSV for variant annotation")
        self.csvForAnnButton.clicked.connect(self.selectcsvForAnnFile)
        sidebarLayout.addWidget(self.csvForAnnButton)

        """ REFERENCE FILE AND TOOL SELECTION """

        # Reference Genome Selection
        self.referenceFileLabel = QLabel("Reference File:")
        sidebarLayout.addWidget(self.referenceFileLabel)
        self.referenceFileInput = QLineEdit()
        self.referenceFileInput.setPlaceholderText("path/to/reference.fasta")
        self.referenceFileInput.setToolTip("Genome reference file (FASTA format)")
        sidebarLayout.addWidget(self.referenceFileInput)
        self.referenceFileButton = QPushButton("Browse Reference")
        self.referenceFileButton.setObjectName("browseButton")
        self.referenceFileButton.setToolTip("Select genome reference file")
        self.referenceFileButton.clicked.connect(self.selectReferenceFile)
        sidebarLayout.addWidget(self.referenceFileButton)

        # Aligner Selection Dropdown
        self.alignerLabel = QLabel("Aligner:")
        sidebarLayout.addWidget(self.alignerLabel)
        self.alignerDropdown = QComboBox()
        self.alignerDropdown.addItems(["bwa", "bwamem2"])
        self.alignerDropdown.setToolTip("Select alignment algorithm")
        sidebarLayout.addWidget(self.alignerDropdown)

        # Variant Calling Options
        self.callsnpLabel = QLabel("Callsnp Option:")
        sidebarLayout.addWidget(self.callsnpLabel)
        self.callsnpDropdown = QComboBox()
        self.callsnpDropdown.addItems(["Defaults", "onlyVCF", "cohortGVCF"])
        self.callsnpDropdown.setToolTip("Variant calling output mode")
        sidebarLayout.addWidget(self.callsnpDropdown)

        # VCF Selection Group
        self.createVcfSelectionGroup()
        sidebarLayout.addWidget(self.vcfSelectionGroup)

        """ Group box for profile selection"""
        # Create a group box for profile selection
        self.profileGroup = QGroupBox("Profiles")
        self.profileLayout = QVBoxLayout()

        # Create checkboxes for each profile
        self.profileCheckboxes = {}
        profiles = ["standard", "conda", "mamba", "docker", "singularity", "wave", "test"]
        for profile in profiles:
            cb = QCheckBox(profile)
            cb.stateChanged.connect(self.profileSelection)
            self.profileCheckboxes[profile] = cb
            self.profileLayout.addWidget(cb)

        # Set standard profile as default selected
        self.profileCheckboxes["standard"].setChecked(True)

        self.profileGroup.setLayout(self.profileLayout)
        sidebarLayout.addWidget(self.profileGroup)

        """ VEP parameters """
        self.vepSpeciesLabel = QLabel("Species:")
        self.vepSpeciesInput = QLineEdit()
        self.vepSpeciesInput.setPlaceholderText("e.g., homo_sapiens")
        sidebarLayout.addWidget(self.vepSpeciesLabel)
        sidebarLayout.addWidget(self.vepSpeciesInput)

        self.vepAssemblyLabel = QLabel("Assembly:")
        self.vepAssemblyInput = QLineEdit()
        self.vepAssemblyInput.setPlaceholderText("e.g., GRCh38")
        sidebarLayout.addWidget(self.vepAssemblyLabel)
        sidebarLayout.addWidget(self.vepAssemblyInput)

        self.vepCacheTypeLabel = QLabel("Cache Type:")
        self.vepCacheTypeDropdown = QComboBox()
        self.vepCacheTypeDropdown.addItems(["vep", "refseq", "merged"])
        sidebarLayout.addWidget(self.vepCacheTypeLabel)
        sidebarLayout.addWidget(self.vepCacheTypeDropdown)

        self.vepCacheVersionLabel = QLabel("Cache Version:")
        self.vepCacheVersionInput = QLineEdit()
        self.vepCacheVersionInput.setPlaceholderText("e.g., 110")
        sidebarLayout.addWidget(self.vepCacheVersionLabel)
        sidebarLayout.addWidget(self.vepCacheVersionInput)
        self.toggleOptions(self.optionDropdown.currentText())

        """ Add Control buttons at the bottom """
        sidebarLayout.addStretch(1)   # Add a stretch to push everything up

        # Run button
        self.runButton = QPushButton("Run Pipeline")
        self.runButton.setObjectName("runButton")
        self.runButton.clicked.connect(self.runPipeline)
        sidebarLayout.addWidget(self.runButton)

        # Abort button
        self.abortButton = QPushButton("Abort Pipeline")
        self.abortButton.setObjectName("abortButton")
        self.abortButton.clicked.connect(self.abortPipeline)
        self.abortButton.setEnabled(False)
        sidebarLayout.addWidget(self.abortButton)

        # Back button
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
        """ Create the scrollable sidebar """
        sidebarWidget = QWidget()
        sidebarWidget.setLayout(sidebarLayout)

        # Configure the scroll area
        scrollArea = QScrollArea()
        scrollArea.setWidgetResizable(True)  # Critical for dynamic resizing
        scrollArea.setWidget(sidebarWidget)
        scrollArea.setVerticalScrollBarPolicy(Qt.ScrollBarAsNeeded)
        scrollArea.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)  # No horizontal scroll

        # Fix width behavior
        scrollArea.setMinimumWidth(220)     # Set minimum width for sidebar
        sidebarWidget.setMinimumWidth(200)  # Slightly less to account for scrollbar

        """ Log output and main layout"""
        self.logOutput = QTextEdit()
        self.logOutput.setReadOnly(True)
        self.logOutput.setFontFamily("Courier")
        self.logOutput.setLineWrapMode(QTextEdit.NoWrap)

        mainLayout = QHBoxLayout()
        mainLayout.addWidget(scrollArea, 1)  # Scrollable sidebar (stretch factor 1)
        mainLayout.addWidget(self.logOutput, 8)  # Log area takes most space (stretch factor 8)

        self.setLayout(mainLayout)

    def selectWorkflow(self):
        filePath, _ = QFileDialog.getOpenFileName(self, "Select Workflow File", "", "Nextflow Files (*.nf)")
        if filePath:
            self.workflowInput.setText(filePath)

    def profileSelection(self):
        """Enforce profile selection rules:
            - Standard profile is selected by default
            - Can select multiple profiles
            - Cannot select conda/mamba/docker/singularity together
        """
        sender = self.sender()

        # Prevent unchecking the standard profile
        if sender == self.profileCheckboxes["standard"] and not sender.isChecked():
            sender.setChecked(True)
            return

        currentProfile = [name for name, cb in self.profileCheckboxes.items() if cb == sender][0]

        # List of mutually exclusive profiles
        exclusiveProfiles = ["conda", "mamba", "docker", "singularity", "wave"]

        # If current selection is in exclusive group
        if currentProfile in exclusiveProfiles and sender.isChecked():
            # Uncheck other exclusive profiles
            for profile in exclusiveProfiles:
                if profile != currentProfile and self.profileCheckboxes[profile].isChecked():
                    self.profileCheckboxes[profile].setChecked(False)

        # Enable/disable checkboxes based on current selection
        selectedProfiles = [name for name, cb in self.profileCheckboxes.items() if cb.isChecked()]

        # If any exclusive profile is selected, disable others in the group
        anyExclusiveSelected = any(p in selectedProfiles for p in exclusiveProfiles)
        for profile in exclusiveProfiles:
            self.profileCheckboxes[profile].setEnabled(
                not anyExclusiveSelected or profile in selectedProfiles
            )

    def updateCpuCoresLabel(self, value):
        self.cpuCoresLabel.setText(f"CPU Cores: {value} (max: {os.cpu_count() or 2})")

    def selectCsvFile(self):
        filePath, _ = QFileDialog.getOpenFileName(self, "Select CSV File", "", "CSV Files (*.csv)")
        if filePath:
            self.csvInput.setText(filePath)

    def selectCsvForRawQcFile(self):
        filePath, _ = QFileDialog.getOpenFileName(self, "Select CSV for Raw QC", "", "CSV Files (*.csv)")
        if filePath:
            self.csvForRawQcInput.setText(filePath)

    def selectCsvForTrimmingFile(self):
        filePath, _ = QFileDialog.getOpenFileName(self, "Select CSV for Trimming", "", "CSV Files (*.csv)")
        if filePath:
            self.csvForTrimmingInput.setText(filePath)

    def selectCsvForAssemblyFile(self):
        filePath, _ = QFileDialog.getOpenFileName(self, "Select CSV for Alignment", "", "CSV Files (*.csv)")
        if filePath:
            self.csvForAssemblyInput.setText(filePath)

    def selectCsvForBqsrFile(self):
        filePath, _ = QFileDialog.getOpenFileName(self, "Select CSV for Bqsr", "", "CSV Files (*.csv)")
        if filePath:
            self.csvForBqsrInput.setText(filePath)

    def selectcsvForVarCFile(self):
        filePath, _ = QFileDialog.getOpenFileName(self, "Select CSV for Variant Calling", "", "CSV Files (*.csv)")
        if filePath:
            self.csvForVarCInput.setText(filePath)

    def selectcsvForAnnFile(self):
        filePath, _ = QFileDialog.getOpenFileName(self, "Select CSV for Annotation", "", "CSV Files (*.csv)")
        if filePath:
            self.csvForAnnInput.setText(filePath)

    def selectReferenceFile(self):
        filePath, _ = QFileDialog.getOpenFileName(self, "Select Reference File", "", "FASTA Files (*.fa *.fasta)")
        if filePath:
            self.referenceFileInput.setText(filePath)

    def toggleOptions(self, selectedExec):

        isGenerateCsv = selectedExec == "Generate CSV"
        isRawqc = selectedExec == "rawqc"
        isTrim = selectedExec == "trim"
        isRefidx = selectedExec == "refidx"
        isAlign = selectedExec == "align"
        isBqsr = selectedExec == "bqsr"
        isCallsnp = selectedExec == "callsnp"
        isVepCache = selectedExec == "vepcache"
        isVepAnnotate = selectedExec == "vepannotate"

        # Show/hide elements based on selected option
        self.csvLabel.setVisible(isGenerateCsv)
        self.csvInput.setVisible(isGenerateCsv)
        self.csvButton.setVisible(isGenerateCsv)

        self.csvForRawQcLabel.setVisible(isRawqc)
        self.csvForRawQcInput.setVisible(isRawqc)
        self.csvForRawQcButton.setVisible(isRawqc)

        self.trimmerLabel.setVisible(isTrim)
        self.trimmerDropdown.setVisible(isTrim)
        self.csvForTrimmingLabel.setVisible(isTrim)
        self.csvForTrimmingInput.setVisible(isTrim)
        self.csvForTrimmingButton.setVisible(isTrim)

        self.csvForAssemblyLabel.setVisible(isAlign)
        self.csvForAssemblyInput.setVisible(isAlign)
        self.csvForAssemblyButton.setVisible(isAlign)

        self.csvForBqsrLabel.setVisible(isBqsr)
        self.csvForBqsrInput.setVisible(isBqsr)
        self.csvForBqsrButton.setVisible(isBqsr)
        self.vcfSelectionGroup.setVisible(isBqsr)

        self.csvForVarCLabel.setVisible(isCallsnp)
        self.csvForVarCInput.setVisible(isCallsnp)
        self.csvForVarCButton.setVisible(isCallsnp)

        self.csvForAnnLabel.setVisible(isVepAnnotate)
        self.csvForAnnInput.setVisible(isVepAnnotate)
        self.csvForAnnButton.setVisible(isVepAnnotate)

        self.referenceFileLabel.setVisible(isRefidx or isAlign or isBqsr or isCallsnp or isVepAnnotate)
        self.referenceFileInput.setVisible(isRefidx or isAlign or isBqsr or isCallsnp or isVepAnnotate)
        self.referenceFileButton.setVisible(isRefidx or isAlign or isBqsr or isCallsnp or isVepAnnotate)

        self.alignerLabel.setVisible(isRefidx or isAlign)
        self.alignerDropdown.setVisible(isRefidx or isAlign)

        self.callsnpLabel.setVisible(isCallsnp)
        self.callsnpDropdown.setVisible(isCallsnp)
        showVepParams = isVepCache or isVepAnnotate
        self.vepSpeciesLabel.setVisible(showVepParams)
        self.vepSpeciesInput.setVisible(showVepParams)
        self.vepAssemblyLabel.setVisible(showVepParams)
        self.vepAssemblyInput.setVisible(showVepParams)
        self.vepCacheTypeLabel.setVisible(showVepParams)
        self.vepCacheTypeDropdown.setVisible(showVepParams)
        self.vepCacheVersionLabel.setVisible(showVepParams)
        self.vepCacheVersionInput.setVisible(showVepParams)

    def createVcfSelectionGroup(self):
        """Create the VCF source selection widgets (radio buttons horizontal, inputs vertical)"""
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

        # Bundle VCF widgets - now with two combo boxes
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
        self.referenceCombo.currentTextChanged.connect(self.updateBundleOptions)

        # Set default
        self.localVcfRadio.setChecked(True)
        self.bundleVcfWidget.setVisible(False)


    def toggleVcfSource(self, checked):
        """Toggle between local and bundle VCF sources"""
        self.localVcfWidget.setVisible(checked)
        self.bundleVcfWidget.setVisible(not checked)

    def updateBundleOptions(self):
        """Update the bundle options with exact parameter names from the Nextflow params"""
        reference = self.referenceCombo.currentText()
        self.bundle1Combo.clear()
        self.bundle2Combo.clear()

        # Mapping of reference genome to available bundles (exact parameter names)
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

    def browseVcfFile(self, lineEdit):
        """Open file dialog to select VCF file"""
        filePath, _ = QFileDialog.getOpenFileName(
            self, "Select VCF File", "", "VCF Files (*.vcf *.vcf.gz)"
        )
        if filePath:
            lineEdit.setText(filePath)

    def runPipeline(self):
        workflow = self.workflowInput.text()
        selectedCores = self.cpuCoresSlider.value()
        selectedExec = self.optionDropdown.currentText()
        selectedProfiles = [name for name, cb in self.profileCheckboxes.items() if cb.isChecked()]

        # Validate profile selection
        if not selectedProfiles:
            QMessageBox.critical(self, "Error", "Please select at least one profile.")
            return

        if len(selectedProfiles) > 2:
            QMessageBox.critical(self, "Error", "Please select no more than two profiles.")
            return

        if "standard" in selectedProfiles and "test" in selectedProfiles:
            QMessageBox.critical(self, "Error", "Cannot select both 'standard' and 'test' profiles together.")
            return

        profile = ",".join(selectedProfiles)
        isTestProfile = "test" in profile.split(",")

        # Get other parameters
        callsnpOption = self.callsnpDropdown.currentText() if selectedExec == "callsnp" else None
        csvFile = self.csvInput.text() if selectedExec == "Generate CSV" else None
        csvForRawQc = self.csvForRawQcInput.text() if selectedExec == "rawqc" else None
        csvForTrimming = self.csvForTrimmingInput.text() if selectedExec == "trim" else None
        csvForAssembly = self.csvForAssemblyInput.text() if selectedExec == "align" else None
        csvForBqsr = self.csvForBqsrInput.text() if selectedExec == "bqsr" else None
        csvForVarC = self.csvForVarCInput.text() if selectedExec == "callsnp" else None
        csvForAnn = self.csvForAnnInput.text() if selectedExec == "vepannotate" else None

        vcf1 = self.vcf1Input.text().strip() if selectedExec == "bqsr" else None
        vcf2 = self.vcf2Input.text().strip() if selectedExec == "bqsr" else None
        referenceFile = self.referenceFileInput.text() if selectedExec in ["refidx", "align", "bqsr",
                                                                           "callsnp", "vepannotate"] else None

        # Get VEP parameters if needed
        species = self.vepSpeciesInput.text().strip() if selectedExec in ["vepcache", "vepannotate"] else None
        assembly = self.vepAssemblyInput.text().strip() if selectedExec in ["vepcache", "vepannotate"] else None
        cachetype = self.vepCacheTypeDropdown.currentText() if selectedExec in ["vepcache", "vepannotate"] else None
        cacheversion = self.vepCacheVersionInput.text().strip() if selectedExec in ["vepcache", "vepannotate"] else None

        # Validate VEP parameters if needed
        if selectedExec in ["vepcache", "vepannotate"] and not isTestProfile:
            missing = []
            if not species:
                missing.append("species")
            if not assembly:
                missing.append("assembly")
            if not cacheversion:
                missing.append("cache version")

            if missing:
                QMessageBox.critical(
                    self,
                    "Error",
                    "Missing required VEP parameters:\n• " + "\n• ".join(missing)
                )
                return

        # Validate inputs (skip certain checks for test profile)
        if not workflow:
            QMessageBox.critical(self, "Error", "Please select a workflow file before running the pipeline.")
            return

        if selectedExec == "Generate CSV" and not csvFile and not isTestProfile:
            QMessageBox.critical(self, "Error", "Please select a CSV file for 'Generate CSV'.")
            return

        if selectedExec == "rawqc" and not csvForRawQc and not isTestProfile:
            QMessageBox.critical(self, "Error", "Please select a CSV file for Raw QC.")
            return

        if selectedExec == "trim" and not csvForTrimming and not isTestProfile:
            QMessageBox.critical(self, "Error", "Please select a CSV file for Trimming.")
            return

        if selectedExec == "refidx" and not referenceFile and not isTestProfile:
            QMessageBox.critical(self, "Error", "Please select a reference file for refidx.")
            return

        if selectedExec == "align" and not csvForAssembly and not isTestProfile:
            QMessageBox.critical(self, "Error", "Please select a CSV file for Assembly.")
            return

        if selectedExec == "align" and not referenceFile and not isTestProfile:
            QMessageBox.critical(self, "Error", "Please select a reference file for Alignment.")
            return

        if selectedExec == "bqsr":
            missing = []
            if not csvForBqsr and not isTestProfile:
                missing.append("BQSR CSV file")
            if not referenceFile and not isTestProfile:
                missing.append("reference file")

            vcf1 = None
            vcf2 = None
            bundle_vcfs = []

            if not isTestProfile:  # Skip VCF checks for test profile
                if self.localVcfRadio.isChecked():
                    vcf1 = self.vcf1Input.text().strip()
                    vcf2 = self.vcf2Input.text().strip()
                    if not vcf1:
                        missing.append("VCF file 1")
                else:
                    bundle1 = self.bundle1Combo.currentData()
                    if bundle1:
                        bundle_vcfs.append(bundle1)
                        bundle2 = self.bundle2Combo.currentData()
                        if bundle2:
                            bundle_vcfs.append(bundle2)
                    else:
                        missing.append("primary VCF bundle")

            if missing and not isTestProfile:
                QMessageBox.critical(
                    self,
                    "Error",
                    "Missing required fields:\n• " + "\n• ".join(missing)
                )
                return

        if selectedExec == "callsnp":
            missing = []
            if not referenceFile and not isTestProfile:
                missing.append("reference file")
            if not csvForVarC and not isTestProfile:
                missing.append("variant calling CSV file")

            if missing and not isTestProfile:
                QMessageBox.critical(
                    self,
                    "Error",
                    "Missing required fields for variant calling:\n• " + "\n• ".join(missing)
                )
                return

        self.logOutput.clear()
        self.logOutput.append("Starting Nextflow pipeline...\n")

        # Create and start the runner thread
        self.runnerThread = FullParamsRunnerThread(
            workflow=workflow,
            selectedExec=selectedExec,
            profile=profile,
            generateOption=callsnpOption,
            csvFile=csvFile,
            csvForRawQc=csvForRawQc,
            csvForTrimming=csvForTrimming,
            csvForAssembly=csvForAssembly,
            csvForBqsr=csvForBqsr,
            csvForVarC=csvForVarC,
            csvForAnn=csvForAnn ,
            vcf1=vcf1,
            vcf2=vcf2,
            referenceFile=referenceFile,
            aligner=self.alignerDropdown.currentText() if selectedExec in ["refidx", "align"] else None,
            trimmer=self.trimmerDropdown.currentText() if selectedExec == "trim" else None,
            cores=selectedCores,
            bundleVcf=bundle_vcfs if selectedExec == "bqsr" and not self.localVcfRadio.isChecked() and not isTestProfile else None,
            species=species,
            assembly=assembly,
            cachetype=cachetype,
            cacheversion=cacheversion
        )
        self.runnerThread.logSignal.connect(self.logOutput.append)
        self.runnerThread.finishedSignal.connect(self.pipelineFinished)
        self.runnerThread.start()

        self.runButton.setEnabled(False)
        self.abortButton.setEnabled(True)

    def abortPipeline(self):
        if hasattr(self, 'runnerThread') and self.runnerThread is not None:
            self.runnerThread.stop()
            self.runnerThread = None  # Clean up the reference
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


__all__ = ['sMFullParamsPage']
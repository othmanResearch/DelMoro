import os
import subprocess
from PyQt5.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel, QLineEdit,
    QPushButton, QComboBox, QTextEdit, QMessageBox, QFileDialog,
    QSlider, QCheckBox, QGroupBox
)
from PyQt5.QtCore import QThread, pyqtSignal, Qt


class DelMoroRunnerThread(QThread):
    """
    A QThread subclass for executing DelMoro pipeline in the background by :
        - Emitting signals for real-time logging and completion status.
        &
        - Handling execution, parameter validation, and process management.
    """

    # Custom signals for thread communication
    logSignal = pyqtSignal(str)         # Signal for sending log messages to UI
    finishedSignal = pyqtSignal(bool)   # Signal for execution completion status (True=success, False=failure)

    def __init__(self, workflow, profile, paramsFile, output, selectedExec, generateOption, csvFilePath=None,
                 trimmer=None, cores=2):
        """ Initialize the pipeline runner thread. """
        super().__init__()
        # Store execution parameters
        self.workflow = workflow
        self.profile = profile          # Nextflow profile configuration
        self.cores = cores              # CPU cores for pipeline execution
        self.paramsFile = paramsFile    # Parameters file path
        self.output = output            # Output directory
        self.selectedExec = selectedExec        # Selected execution mode
        self.generateOption = generateOption    # Generation option
        self.csvFilePath = csvFilePath          # Optional CSV file path
        self.trimmer = trimmer          # Optional trimmer selection
        self.process = None             # Will hold the subprocess reference

    def run(self):
        """ Main thread execution method. """
        try:
            # Validate workflow file exists
            if not os.path.exists(self.workflow):
                self.logSignal.emit(f"Error: Workflow file '{self.workflow}' does not exist.\n")
                self.finishedSignal.emit(False)
                return

            # Check if using test profile
            isTestProfile = "test" in self.profile.split(",")

            # Validate params file exists (unless in test mode)
            if not isTestProfile and self.paramsFile and not os.path.exists(self.paramsFile):
                self.logSignal.emit(f"Error: Params file '{self.paramsFile}' does not exist.\n")
                self.finishedSignal.emit(False)
                return

            # Build BASE Nextflow command
            cmd = ["nextflow", "run", self.workflow, "-profile", self.profile, "--pcpus", str(self.cores), "--stepmode"]

            # Add params file if not in test profile and exists
            if not isTestProfile and self.paramsFile:
                cmd.extend(["-params-file", self.paramsFile])

            # Handle execution options based on profile and selected mode
            if isTestProfile:
                # Simplified command for test profile
                cmd.extend(["--exec", self.selectedExec])
            else:
                if self.selectedExec == "Generate CSV" and self.csvFilePath:
                    # CSV generation mode
                    cmd.extend(["--generate", "CSV", "--basedon", self.csvFilePath])
                elif self.selectedExec == "trim" and self.trimmer:
                    # Read trimming mode
                    cmd.extend(["--exec", self.selectedExec, f"--{self.trimmer}"])
                elif self.generateOption != "Defaults":
                    # Standard execution with generation option
                    cmd.extend(["--exec", self.selectedExec, "--mode", self.generateOption])
                else:
                    # Default execution
                    cmd.extend(["--exec", self.selectedExec])

            # Log the full command being executed
            self.logSignal.emit(f"Running command: {' '.join(cmd)}\n")

            # Launch the Nextflow process
            self.process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                universal_newlines=True
            )

            # Stream stdout and stderr to UI
            for line in self.process.stdout:
                self.logSignal.emit(line)
            for line in self.process.stderr:
                self.logSignal.emit(f"ERROR: {line.strip()}")

            # Wait for process completion
            self.process.wait()

            # Emit appropriate completion signal
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
        """ Sends termination signal to the process and cleans up resources. """
        if self.process:
            self.process.terminate()    # Send SIGTERM to process
            self.process = None         # Clear process reference
            self.logSignal.emit("Pipeline execution aborted.\n")
            self.finishedSignal.emit(False)

class sMJsonFilesPage(QWidget):
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

        #browseButton {
            background-color: #4299e1;
            color: white;
        }

        #browseButton:hover {
            background-color: #3182ce;
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
            background: #4a5568;
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

        """ Parameters File Selection Widgets for selecting and displaying the Nextflow parameters file """

        # Create parameters file label
        self.paramsLabel = QLabel("Params File:")  # Descriptive label for params file input
        sidebarLayout.addWidget(self.paramsLabel)  # Add label to sidebar layout

        # Create parameters file path input field
        self.paramsInput = QLineEdit()  # Text field for displaying/editing params file path
        self.paramsInput.setPlaceholderText("Parameters file ")  # Hint text
        sidebarLayout.addWidget(self.paramsInput)  # Add input field to layout

        # Create parameters file browse button
        self.paramsButton = QPushButton("Browse Params")  # Button to open file dialog
        self.paramsButton.setObjectName("browseButton")  # Set CSS identifier for styling
        self.paramsButton.setToolTip("Select Nextflow parameters JSON/YAML file")  # Help text
        self.paramsButton.clicked.connect(self.selectParamsFile)  # Connect to file selection handler
        sidebarLayout.addWidget(self.paramsButton)                # Add button to layout

        """ Execution Option Selection Widgets """

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
        self.optionDropdown.setCurrentIndex(0)                              # Default to first option
        self.optionDropdown.currentTextChanged.connect(self.toggleOptions)  # Connect selection change handler
        sidebarLayout.addWidget(self.optionDropdown)                        # Add dropdown to layout

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

        """ Variant Calling Options Widgets For Configuring SNP Calling Options """

        self.callsnpLabel = QLabel("Callsnp Option:")   # Label for variant calling options
        sidebarLayout.addWidget(self.callsnpLabel)      # Add label to layout
        self.callsnpDropdown = QComboBox()              # Dropdown for SNP calling modes
        self.callsnpDropdown.addItems([
            "Defaults",     # Default, no special option
            "cohort"    # Generate cohort GVCFs
        ])
        sidebarLayout.addWidget(self.callsnpDropdown)  # Add dropdown to layout

        """ CSV File Selection Widgets for handling CSV input files """

        self.csvLabel = QLabel("CSV File:")     # Label for CSV file input
        sidebarLayout.addWidget(self.csvLabel)  # Add label to layout
        self.csvInput = QLineEdit()                         # Text field for CSV file path
        self.csvInput.setPlaceholderText("Select CSV file") # Hint text
        sidebarLayout.addWidget(self.csvInput)              # Add input field to layout
        self.csvButton = QPushButton("Browse CSV")          # Button for file dialog
        self.csvButton.setObjectName("browseButton")        # CSS identifier for styling
        self.csvButton.setToolTip("Select sample CSV file") # Help text
        self.csvButton.clicked.connect(self.selectCsvFile)  # Connect to file selection handler
        sidebarLayout.addWidget(self.csvButton)             # Add button to layout

        """ Initialize UI State  based on current selection """
        self.toggleOptions(self.optionDropdown.currentText())  # Apply initial UI state

        """ Profile Selection Group Box """
        self.profileGroup = QGroupBox("Profiles")   # Container with title
        self.profileLayout = QVBoxLayout()          # Vertical layout for profile options
        self.profileCheckboxes = {}                 # Dictionary to store profile checkboxes
        profiles = [
            "standard",     # Default local execution
            "conda",        # Conda package manager
            "mamba",        # Mamba package manager
            "docker",       # Docker containerization
            "singularity",  # Singularity containerization
            "wave",         # Wave containers
            "test"          # Test configuration
        ]

        # Create and configure checkboxes for each profile
        for profile in profiles:
            cb = QCheckBox(profile)                         # Create checkbox with profile name
            cb.stateChanged.connect(self.profileSelection)  # Connect state change handler
            self.profileCheckboxes[profile] = cb            # Store reference in dictionary
            self.profileLayout.addWidget(cb)                # Add to profile layout

        self.profileCheckboxes["standard"].setChecked(True) # Set Default Profile to standard profile
        self.profileGroup.setLayout(self.profileLayout)     # Apply layout to group box
        sidebarLayout.addWidget(self.profileGroup)          # Add group box to sidebar

        """ Bottom Action Buttons """
        sidebarLayout.addStretch(1)  # Add expanding space to push buttons to bottom

        # Run Pipeline Button
        self.runButton = QPushButton("Run Pipeline")        # Main execution button
        self.runButton.setObjectName("runButton")           # CSS identifier for styling
        self.runButton.clicked.connect(self.runPipeline)    # Connect to execution handler
        sidebarLayout.addWidget(self.runButton)

        # Abort Pipeline Button
        self.abortButton = QPushButton("Abort Pipeline")    # Pipeline termination button
        self.abortButton.setObjectName("abortButton")       # CSS identifier
        self.abortButton.clicked.connect(self.abortPipeline)# Connect abort handler
        self.abortButton.setEnabled(False)                  # Disabled by default (no running pipeline)
        sidebarLayout.addWidget(self.abortButton)

        # Navigation Button
        backButton = QPushButton("Back to Welcome")     # Return to home screen button
        backButton.setObjectName("backButton")          # CSS identifier
        backButton.clicked.connect(self.mainWindow.showWelcomePage)  # Connect navigation
        sidebarLayout.addWidget(backButton)

        # Log Output Configuration
        self.logOutput = QTextEdit()            # Text area for pipeline output
        self.logOutput.setReadOnly(True)        # Make read-only
        self.logOutput.setFontFamily("Courier") # Monospace font for log alignment
        self.logOutput.setLineWrapMode(QTextEdit.NoWrap)  # Prevent line wrapping

        # Main Layout Assembly
        mainLayout = QHBoxLayout()  # Horizontal split layout
        sidebarWidget = QWidget()   # Container for sidebar elements
        sidebarWidget.setLayout(sidebarLayout)  # Apply sidebar layout
        mainLayout.addWidget(sidebarWidget, 1)  # Add sidebar (1/9th of width)
        mainLayout.addWidget(self.logOutput, 8)  # Add log area (8/9ths of width)

        self.setLayout(mainLayout)  # Apply main layout to window

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

    def selectParamsFile(self):
        filePath, _ = QFileDialog.getOpenFileName(self, "Select Params File", "", "JSON Files (*.json)")
        if filePath:
            self.paramsInput.setText(filePath)

    def selectCsvFile(self):
        filePath, _ = QFileDialog.getOpenFileName(self, "Select CSV File", "", "CSV Files (*.csv)")
        if filePath:
            self.csvInput.setText(filePath)

    def toggleOptions(self, selectedExec):
        isCallsnp = selectedExec == "callsnp"
        isCsv = selectedExec == "Generate CSV"
        isTrim = selectedExec == "trim"

        self.callsnpLabel.setVisible(isCallsnp)
        self.callsnpDropdown.setVisible(isCallsnp)
        self.csvLabel.setVisible(isCsv)
        self.csvInput.setVisible(isCsv)
        self.csvButton.setVisible(isCsv)
        self.trimmerLabel.setVisible(isTrim)
        self.trimmerDropdown.setVisible(isTrim)

    def runPipeline(self):
        workflow = self.workflowInput.text()
        selectedProfiles = [name for name, cb in self.profileCheckboxes.items() if cb.isChecked()]
        selectedCores = self.cpuCoresSlider.value()
        paramsFile = self.paramsInput.text()
        selectedExec = self.optionDropdown.currentText()
        callsnpOption = self.callsnpDropdown.currentText()
        csvFilePath = self.csvInput.text()
        trimmer = self.trimmerDropdown.currentText() if selectedExec == "trim" else None
        isTestProfile = "test" in ",".join(selectedProfiles).split(",")

        # Basic validations
        if not workflow:
            QMessageBox.critical(self, "Error", "Please select a workflow file before running the pipeline.")
            return

        # Only require params file if not in test profile
        if not isTestProfile and not paramsFile:
            QMessageBox.critical(self, "Error", "Please select a params file before running the pipeline.")
            return

        if selectedExec == "Generate CSV" and not csvFilePath:
            QMessageBox.critical(self, "Error", "Please select a CSV file for 'Generate CSV'.")
            return

        # Profile validations
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

        self.logOutput.clear()
        self.logOutput.append("Starting Nextflow pipeline...\n")

        self.runnerThread = DelMoroRunnerThread(
            workflow,
            profile,
            paramsFile if not isTestProfile else None,  # Pass None for paramsFile in test mode
            "",
            selectedExec,
            callsnpOption,
            csvFilePath,
            trimmer,
            cores=selectedCores
        )
        self.runnerThread.logSignal.connect(self.logOutput.append)
        self.runnerThread.finishedSignal.connect(self.pipelineFinished)
        self.runnerThread.start()

        self.runButton.setEnabled(False)
        self.abortButton.setEnabled(True)

    def abortPipeline(self):
        if hasattr(self, 'runnerThread'):
            self.runnerThread.stop()
        self.runButton.setEnabled(True)
        self.abortButton.setEnabled(False)

    def pipelineFinished(self, success):
        self.runButton.setEnabled(True)
        self.abortButton.setEnabled(False)
        if success:
            QMessageBox.information(self, "Success", "Pipeline completed successfully!")
            self.logOutput.append("\nPipeline finished successfully!")
        else:
            QMessageBox.critical(self, "Error", "Pipeline failed! Check the log for details.")
            self.logOutput.append("\nPipeline failed.")


__all__ = ['sMJsonFilesPage']

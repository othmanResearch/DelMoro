import sys
import os
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QVBoxLayout, QHBoxLayout,
    QPushButton, QLabel, QWidget, QStackedWidget, QDesktopWidget
) 
from PyQt5.QtCore import Qt, QSize
from PyQt5.QtGui import QFont, QPixmap, QPalette

""" Importing Customized Pages :NextflowRunnerPage & FullParamsPage """
from paramsFile import NextflowRunnerPage
from fullParams import FullParamsPage


class WelcomePage(QWidget):
    def __init__(self, mainWindow):
        super().__init__()
        self.mainWindow = mainWindow
        self.setupUi()

    def setupUi(self):
        """Setup the welcome page UI with logo, labels, and buttons."""
        """ Set white background """
        self.setAutoFillBackground(True)
        palette = self.palette()
        palette.setColor(QPalette.Window, Qt.white)
        self.setPalette(palette)

        """ Main layout (vertical) """
        mainLayout = QVBoxLayout()
        mainLayout.setAlignment(Qt.AlignCenter)
        mainLayout.setSpacing(20)  # Uniform spacing between widgets

        """ Welcome label """
        welcomeLabel = QLabel("Welcome to DelMoro Pipeline")
        welcomeLabel.setFont(QFont('Arial', 24, QFont.Bold))
        welcomeLabel.setAlignment(Qt.AlignCenter)

        """ Subtitle label """
        subtitleLabel = QLabel("Please choose an option to continue")
        subtitleLabel.setFont(QFont('Arial', 14))
        subtitleLabel.setAlignment(Qt.AlignCenter)

        """ Logo setup """
        logoLabel = QLabel()
        logoPixmap = QPixmap(self.resource_path("delmoro.png"))
        logoPixmap = logoPixmap.scaled(200, 200, Qt.KeepAspectRatio, Qt.SmoothTransformation)
        logoLabel.setPixmap(logoPixmap)
        logoLabel.setAlignment(Qt.AlignCenter)

        """ Buttons """
        btnFullParams = self.createButton("Use Full Parameters", "#4CAF50", self.mainWindow.showFullParamsPage)
        btnParamsFile = self.createButton("Use Params File", "#2196F3", self.mainWindow.showNextflowRunner)

        """ Button container (horizontal layout) """
        buttonLayout = QHBoxLayout()
        buttonLayout.addStretch()
        buttonLayout.addWidget(btnFullParams)
        buttonLayout.addWidget(btnParamsFile)
        buttonLayout.addStretch()

        """ Add widgets to main layout in desired order """
        mainLayout.addStretch()
        mainLayout.addWidget(welcomeLabel)
        mainLayout.addWidget(subtitleLabel)
        mainLayout.addWidget(logoLabel)  # Logo position
        mainLayout.addSpacing(30)  # Extra space before buttons
        mainLayout.addLayout(buttonLayout)
        mainLayout.addStretch()

        self.setLayout(mainLayout)

    def resource_path(self, relative_path):
        """
        Get absolute path to resource, works for dev and for PyInstaller.

        Args:
            relative_path (str): Relative path to the resource

        Returns:
            str: Absolute path to the resource
        """
        try:
            base_path = sys._MEIPASS
        except Exception:
            base_path = os.path.abspath(".")

        return os.path.join(base_path, relative_path)

    def createButton(self, text, color, onClick):
        """
        Helper method to create styled buttons.

        Args:
            text (str): Button text
            color (str): Hex color code for button background
            onClick (function): Callback function for button click

        Returns:
            QPushButton: Configured button widget
        """
        button = QPushButton(text)
        button.setFixedSize(200, 50)
        button.setStyleSheet(f"""
            QPushButton {{
                background-color: {color};
                color: white;
                border: none;
                border-radius: 5px;
                font-weight: bold;
            }}
            QPushButton:hover {{
                background-color: {self.brightenColor(color)};
            }}
        """)
        button.clicked.connect(onClick)
        return button

    def brightenColor(self, hexColor, percent=20):
        """
        Brighten a hex color by a specified percentage.
            hexColor (str): Original hex color code (format: "#RRGGBB")
            percent (int): Percentage to brighten (0-100)
        """
        # Remove '#' if present
        hexColor = hexColor.lstrip('#')

        # Convert hex to RGB components (0-255)
        r, g, b = [int(hexColor[i:i + 2], 16) for i in (0, 2, 4)]

        # Brighten each component
        r = min(255, r + int(r * percent / 100))
        g = min(255, g + int(g * percent / 100))
        b = min(255, b + int(b * percent / 100))

        # Convert back to hex
        return "#{:02X}{:02X}{:02X}".format(r, g, b)

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.initUi()

    def center(self):
        """Center the window on the screen using available geometry."""
        frame = self.frameGeometry()
        center_point = QDesktopWidget().availableGeometry().center()
        frame.moveCenter(center_point)
        self.move(frame.topLeft())

    def initUi(self):
        """
        Initialize the main window UI.
        Sets up the stacked widget for multi-page navigation.
        """
        self.setWindowTitle("DelMoro Pipeline")
        self.setMinimumSize(QSize(1100, 900))
        # Center the window
        self.center()

        # Set white background
        self.setAutoFillBackground(True)
        palette = self.palette()
        palette.setColor(QPalette.Window, Qt.white)
        self.setPalette(palette)

        # Stacked widget for multi-page navigation
        self.stackedWidget = QStackedWidget()
        self.setCentralWidget(self.stackedWidget)

        # Create pages
        self.welcomePage = WelcomePage(self)
        self.nextflowRunnerPage = NextflowRunnerPage(self)
        self.fullParamsPage = FullParamsPage(self)

        # Add pages to stacked widget
        self.stackedWidget.addWidget(self.welcomePage)
        self.stackedWidget.addWidget(self.nextflowRunnerPage)
        self.stackedWidget.addWidget(self.fullParamsPage)

        self.showWelcomePage()

    def showWelcomePage(self):
        """Show the welcome page in the stacked widget."""
        self.stackedWidget.setCurrentWidget(self.welcomePage)

    def showNextflowRunner(self):
        """Show the Nextflow runner page in the stacked widget."""
        self.stackedWidget.setCurrentWidget(self.nextflowRunnerPage)

    def showFullParamsPage(self):
        """Show the full parameters page in the stacked widget."""
        self.stackedWidget.setCurrentWidget(self.fullParamsPage)


if __name__ == "__main__":
    """
    Main application entry point.
    Initializes the QApplication and sets up the main window.
    """
    app = QApplication(sys.argv)
    app.setStyle('Fusion')

    # Set application-wide white background
    appPalette = QPalette()
    appPalette.setColor(QPalette.Window, Qt.white)
    app.setPalette(appPalette)

    mainWindow = MainWindow()
    mainWindow.show()
    sys.exit(app.exec_())

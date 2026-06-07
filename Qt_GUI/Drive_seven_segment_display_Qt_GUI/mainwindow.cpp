#include "mainwindow.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGridLayout>
#include <QGroupBox>
#include <QFrame>
#include <QFont>
#include <QDateTime>
#include <QMessageBox>

// ============================================================================
// MainWindow: Qt GUI for controlling Nexys A7 8-digit 7-segment display
// via UART serial port.
//
// Layout:
//   Title bar
//   8 x (LCD display + SpinBox) for digits 1-8
//   Serial port configuration (port, baud, open/close)
//   Send button
//   Communication log
// ============================================================================

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    serial(new QSerialPort(this)),
    isOpen(false)
{
    setupUI();

    // Connect serial port signals
    connect(serial, &QSerialPort::readyRead, this, &MainWindow::onReadyRead);
    connect(serial, &QSerialPort::errorOccurred, this, &MainWindow::onErrorOccurred);

    // Refresh available ports at startup
    onRefreshPorts();
}

MainWindow::~MainWindow()
{
    if (serial->isOpen()) {
        serial->close();
    }
}

// ---------------------------------------------------------------------------
// Build the complete user interface
// ---------------------------------------------------------------------------
void MainWindow::setupUI()
{
    setWindowTitle("Nexys A7 - 7-Segment Display Controller");
    setMinimumSize(850, 580);
    setStyleSheet("QMainWindow { background-color: #f5f5f5; }");

    QWidget *centralWidget = new QWidget(this);
    setCentralWidget(centralWidget);

    QVBoxLayout *mainLayout = new QVBoxLayout(centralWidget);
    mainLayout->setSpacing(12);
    mainLayout->setContentsMargins(20, 15, 20, 15);

    // -----------------------------------------------------------------------
    // Title
    // -----------------------------------------------------------------------
    QLabel *titleLabel = new QLabel("Nexys A7  8-Digit 7-Segment Display Control");
    titleLabel->setAlignment(Qt::AlignCenter);
    QFont titleFont("Arial", 16, QFont::Bold);
    titleLabel->setFont(titleFont);
    titleLabel->setStyleSheet("QLabel { color: #1565C0; padding: 8px; }");
    mainLayout->addWidget(titleLabel);

    // -----------------------------------------------------------------------
    // Digit Display Area
    // -----------------------------------------------------------------------
    QGroupBox *digitGroup = new QGroupBox("Display Digits");
    digitGroup->setStyleSheet(
        "QGroupBox { font-weight: bold; border: 2px solid #bbb; border-radius: 8px;"
        "  margin-top: 10px; padding-top: 15px; background: white; }"
        "QGroupBox::title { subcontrol-origin: margin; left: 15px; padding: 0 8px; }"
    );
    QHBoxLayout *digitLayout = new QHBoxLayout(digitGroup);
    digitLayout->setSpacing(6);

    QFont lcdFont = QFont("Courier New", 28, QFont::Bold);
    QFont spinFont("Arial", 14, QFont::Bold);

    for (int i = 0; i < 8; i++) {
        QVBoxLayout *colLayout = new QVBoxLayout();
        colLayout->setSpacing(4);
        colLayout->setAlignment(Qt::AlignCenter);

        // Digit label (D1-D8)
        QLabel *dLabel = new QLabel(QString("D%1").arg(i + 1));
        dLabel->setAlignment(Qt::AlignCenter);
        dLabel->setStyleSheet("QLabel { font-weight: bold; color: #555; font-size: 11px; }");
        colLayout->addWidget(dLabel);

        // LCD number display (shows current digit)
        displays[i] = new QLCDNumber();
        displays[i]->setDigitCount(1);
        displays[i]->setSegmentStyle(QLCDNumber::Filled);
        displays[i]->display(0);
        displays[i]->setMinimumHeight(70);
        displays[i]->setMinimumWidth(60);
        displays[i]->setStyleSheet(
            "QLCDNumber { background-color: #1a1a2e; color: #ff6b6b;"
            "  border: 2px solid #333; border-radius: 6px; padding: 4px; }"
        );
        colLayout->addWidget(displays[i]);

        // Spin box for setting digit value (0-9)
        digits[i] = new QSpinBox();
        digits[i]->setRange(0, 9);
        digits[i]->setValue(0);
        digits[i]->setAlignment(Qt::AlignCenter);
        digits[i]->setFont(spinFont);
        digits[i]->setMinimumHeight(38);
        digits[i]->setStyleSheet(
            "QSpinBox { border: 2px solid #90CAF9; border-radius: 6px;"
            "  padding: 2px; background: white; font-size: 14px; }"
            "QSpinBox:focus { border-color: #1976D2; }"
            "QSpinBox::up-button { width: 24px; }"
            "QSpinBox::down-button { width: 24px; }"
        );

        // Connect spinbox change to LCD display update
        connect(digits[i], QOverload<int>::of(&QSpinBox::valueChanged),
                this, [this, i](int val) {
                    displays[i]->display(val);
                });

        colLayout->addWidget(digits[i]);

        digitLayout->addLayout(colLayout);
    }
    mainLayout->addWidget(digitGroup);

    // -----------------------------------------------------------------------
    // Serial Port Configuration Area
    // -----------------------------------------------------------------------
    QGroupBox *serialGroup = new QGroupBox("Serial Port Configuration");
    serialGroup->setStyleSheet(
        "QGroupBox { font-weight: bold; border: 2px solid #bbb; border-radius: 8px;"
        "  margin-top: 10px; padding-top: 15px; background: white; }"
        "QGroupBox::title { subcontrol-origin: margin; left: 15px; padding: 0 8px; }"
    );
    QHBoxLayout *serialLayout = new QHBoxLayout(serialGroup);
    serialLayout->setSpacing(10);

    // Port selection
    serialLayout->addWidget(new QLabel("Port:"));
    portCombo = new QComboBox();
    portCombo->setMinimumWidth(200);
    portCombo->setStyleSheet("QComboBox { padding: 4px 8px; border: 2px solid #90CAF9;"
                             "  border-radius: 5px; background: white; }");
    serialLayout->addWidget(portCombo);

    // Baud rate selection
    serialLayout->addWidget(new QLabel("Baud:"));
    baudCombo = new QComboBox();
    baudCombo->addItems({"9600", "19200", "38400", "57600", "115200", "230400", "460800", "921600"});
    baudCombo->setCurrentText("115200");
    baudCombo->setEditable(true);
    baudCombo->setStyleSheet("QComboBox { padding: 4px 8px; border: 2px solid #90CAF9;"
                             "  border-radius: 5px; background: white; }");
    serialLayout->addWidget(baudCombo);

    // Refresh ports button
    QPushButton *refreshBtn = new QPushButton("Refresh");
    refreshBtn->setStyleSheet(
        "QPushButton { background-color: #78909C; color: white; border-radius: 5px;"
        "  padding: 8px 16px; font-weight: bold; }"
        "QPushButton:hover { background-color: #546E7A; }"
    );
    connect(refreshBtn, &QPushButton::clicked, this, &MainWindow::onRefreshPorts);
    serialLayout->addWidget(refreshBtn);

    // Open/Close button
    openCloseBtn = new QPushButton("Open Serial");
    openCloseBtn->setMinimumWidth(120);
    openCloseBtn->setStyleSheet(
        "QPushButton { background-color: #4CAF50; color: white; border-radius: 5px;"
        "  padding: 8px 20px; font-weight: bold; font-size: 13px; }"
        "QPushButton:hover { background-color: #388E3C; }"
    );
    connect(openCloseBtn, &QPushButton::clicked, this, &MainWindow::onOpenClose);
    serialLayout->addWidget(openCloseBtn);

    serialLayout->addStretch();
    mainLayout->addWidget(serialGroup);

    // -----------------------------------------------------------------------
    // Send Button Area
    // -----------------------------------------------------------------------
    QHBoxLayout *sendLayout = new QHBoxLayout();
    sendBtn = new QPushButton("Send to FPGA");
    sendBtn->setMinimumHeight(48);
    sendBtn->setStyleSheet(
        "QPushButton { background-color: #2196F3; color: white; border-radius: 8px;"
        "  padding: 12px 30px; font-size: 16px; font-weight: bold; }"
        "QPushButton:hover { background-color: #1976D2; }"
        "QPushButton:disabled { background-color: #BDBDBD; color: #757575; }"
        "QPushButton:pressed { background-color: #0D47A1; }"
    );
    sendBtn->setEnabled(false);
    connect(sendBtn, &QPushButton::clicked, this, &MainWindow::onSend);
    sendLayout->addStretch();
    sendLayout->addWidget(sendBtn);
    sendLayout->addStretch();
    mainLayout->addLayout(sendLayout);

    // -----------------------------------------------------------------------
    // Communication Log Area
    // -----------------------------------------------------------------------
    QGroupBox *logGroup = new QGroupBox("Communication Log");
    logGroup->setStyleSheet(
        "QGroupBox { font-weight: bold; border: 2px solid #bbb; border-radius: 8px;"
        "  margin-top: 10px; padding-top: 15px; }"
        "QGroupBox::title { subcontrol-origin: margin; left: 15px; padding: 0 8px; }"
    );
    QVBoxLayout *logLayout = new QVBoxLayout(logGroup);

    logEdit = new QPlainTextEdit();
    logEdit->setReadOnly(true);
    logEdit->setMaximumBlockCount(1000);
    logEdit->setMinimumHeight(130);
    logEdit->setStyleSheet(
        "QPlainTextEdit { background-color: #1e1e1e; color: #00e676;"
        "  font-family: 'Consolas', 'Courier New', monospace;"
        "  font-size: 12px; border: 1px solid #555; border-radius: 4px; padding: 6px; }"
    );
    logLayout->addWidget(logEdit);
    mainLayout->addWidget(logGroup);

    // -----------------------------------------------------------------------
    // Status Bar
    // -----------------------------------------------------------------------
    statusLabel = new QLabel("Disconnected");
    statusLabel->setStyleSheet("QLabel { color: #888; font-weight: bold; padding: 2px 8px; }");
    statusBar()->addPermanentWidget(statusLabel);

    // Initial log message
    appendLog("Application started. Select serial port and click 'Open Serial'.");
}

// ---------------------------------------------------------------------------
// Append timestamped message to the log window
// ---------------------------------------------------------------------------
void MainWindow::appendLog(const QString &msg)
{
    QString timestamp = QDateTime::currentDateTime().toString("[hh:mm:ss] ");
    logEdit->appendPlainText(timestamp + msg);
}

// ---------------------------------------------------------------------------
// Refresh the list of available serial ports
// ---------------------------------------------------------------------------
void MainWindow::onRefreshPorts()
{
    QString currentPort = portCombo->currentText().split(" - ").first();
    portCombo->clear();

    QList<QSerialPortInfo> ports = QSerialPortInfo::availablePorts();
    if (ports.isEmpty()) {
        portCombo->addItem("No ports available");
        appendLog("No serial ports detected.");
    } else {
        for (const QSerialPortInfo &info : ports) {
            portCombo->addItem(info.portName() + " - " + info.description());
        }
        appendLog(QString("Found %1 serial port(s).").arg(ports.size()));
    }

    // Try to restore previous selection
    int idx = portCombo->findText(currentPort, Qt::MatchStartsWith);
    if (idx >= 0) {
        portCombo->setCurrentIndex(idx);
    }
}

// ---------------------------------------------------------------------------
// Open or close the serial port
// ---------------------------------------------------------------------------
void MainWindow::onOpenClose()
{
    if (!isOpen) {
        // --- Open serial port ---
        QString portStr = portCombo->currentText().split(" - ").first();
        if (portStr.isEmpty() || portStr == "No ports available") {
            appendLog("ERROR: No valid serial port selected.");
            return;
        }

        serial->setPortName(portStr);
        serial->setBaudRate(baudCombo->currentText().toInt());
        serial->setDataBits(QSerialPort::Data8);
        serial->setStopBits(QSerialPort::OneStop);
        serial->setParity(QSerialPort::NoParity);
        serial->setFlowControl(QSerialPort::NoFlowControl);

        if (serial->open(QIODevice::ReadWrite)) {
            isOpen = true;

            // Update button appearance
            openCloseBtn->setText("Close Serial");
            openCloseBtn->setStyleSheet(
                "QPushButton { background-color: #f44336; color: white; border-radius: 5px;"
                "  padding: 8px 20px; font-weight: bold; font-size: 13px; }"
                "QPushButton:hover { background-color: #d32f2f; }"
            );

            // Enable send button
            sendBtn->setEnabled(true);

            // Update status
            statusLabel->setText(QString("Connected - %1 @ %2 bps")
                                 .arg(portStr)
                                 .arg(baudCombo->currentText()));
            statusLabel->setStyleSheet("QLabel { color: #2E7D32; font-weight: bold; padding: 2px 8px; }");

            appendLog(QString("Serial port opened: %1 @ %2 bps 8N1")
                      .arg(portStr)
                      .arg(baudCombo->currentText()));
        } else {
            appendLog(QString("ERROR: Failed to open port - %1").arg(serial->errorString()));
            QMessageBox::warning(this, "Serial Port Error",
                                 "Failed to open port:\n" + serial->errorString());
        }
    } else {
        // --- Close serial port ---
        serial->close();
        isOpen = false;

        // Update button appearance
        openCloseBtn->setText("Open Serial");
        openCloseBtn->setStyleSheet(
            "QPushButton { background-color: #4CAF50; color: white; border-radius: 5px;"
            "  padding: 8px 20px; font-weight: bold; font-size: 13px; }"
            "QPushButton:hover { background-color: #388E3C; }"
        );

        // Disable send button
        sendBtn->setEnabled(false);

        // Update status
        statusLabel->setText("Disconnected");
        statusLabel->setStyleSheet("QLabel { color: #888; font-weight: bold; padding: 2px 8px; }");

        appendLog("Serial port closed.");
    }
}

// ---------------------------------------------------------------------------
// Send 8 digit values to FPGA
// ---------------------------------------------------------------------------
void MainWindow::onSend()
{
    if (!serial->isOpen()) {
        appendLog("ERROR: Serial port is not open.");
        return;
    }

    // Build 8-byte payload (reverse order: D1 leftmost -> byte 7 -> AN7 leftmost)
    QByteArray payload;
    payload.resize(8);
    for (int i = 0; i < 8; i++) {
        payload[7 - i] = static_cast<char>(digits[i]->value());
    }

    qint64 bytesWritten = serial->write(payload);
    if (bytesWritten == 8) {
        // Build a readable string for the log
        QString digitsStr;
        for (int i = 0; i < 8; i++) {
            digitsStr += QString::number(digits[i]->value());
        }
        appendLog(QString("TX [%1]  (%2 bytes)").arg(digitsStr).arg(bytesWritten));
    } else if (bytesWritten < 0) {
        appendLog(QString("ERROR: Failed to write to serial port - %1")
                  .arg(serial->errorString()));
    } else {
        appendLog(QString("WARNING: Only wrote %1 of 8 bytes").arg(bytesWritten));
    }
}

// ---------------------------------------------------------------------------
// Handle incoming serial data (usually echoes or responses from FPGA)
// ---------------------------------------------------------------------------
void MainWindow::onReadyRead()
{
    QByteArray data = serial->readAll();
    if (!data.isEmpty()) {
        QString hexStr;
        for (int i = 0; i < data.size(); i++) {
            hexStr += QString("%1 ").arg(static_cast<unsigned char>(data[i]), 2, 16, QChar('0'));
        }
        appendLog(QString("RX [%1]").arg(hexStr.trimmed()));
    }
}

// ---------------------------------------------------------------------------
// Handle serial port errors
// ---------------------------------------------------------------------------
void MainWindow::onErrorOccurred(QSerialPort::SerialPortError error)
{
    if (error == QSerialPort::NoError) return;

    appendLog(QString("SERIAL ERROR: %1").arg(serial->errorString()));

    // If the port was disconnected externally, reset the UI
    if (error == QSerialPort::DeviceNotFoundError ||
        error == QSerialPort::ResourceError) {
        if (isOpen) {
            serial->close();
            isOpen = false;
            openCloseBtn->setText("Open Serial");
            openCloseBtn->setStyleSheet(
                "QPushButton { background-color: #4CAF50; color: white; border-radius: 5px;"
                "  padding: 8px 20px; font-weight: bold; font-size: 13px; }"
                "QPushButton:hover { background-color: #388E3C; }"
            );
            sendBtn->setEnabled(false);
            statusLabel->setText("Disconnected");
            statusLabel->setStyleSheet("QLabel { color: #888; font-weight: bold; padding: 2px 8px; }");
            appendLog("Port disconnected unexpectedly. UI reset.");
        }
    }
}

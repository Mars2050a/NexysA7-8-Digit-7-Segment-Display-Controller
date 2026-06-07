#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QSerialPort>
#include <QSerialPortInfo>
#include <QSpinBox>
#include <QLCDNumber>
#include <QComboBox>
#include <QPushButton>
#include <QPlainTextEdit>
#include <QLabel>
#include <QStatusBar>

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void onOpenClose();
    void onSend();
    void onRefreshPorts();
    void onReadyRead();
    void onErrorOccurred(QSerialPort::SerialPortError error);

private:
    void setupUI();
    void appendLog(const QString &msg);

    // Serial port
    QSerialPort *serial;
    QComboBox   *portCombo;
    QComboBox   *baudCombo;
    QPushButton *openCloseBtn;
    bool         isOpen;

    // Digit controls (8 digits, each 0-9)
    QSpinBox    *digits[8];
    QLCDNumber  *displays[8];

    // Actions
    QPushButton *sendBtn;

    // Logging
    QPlainTextEdit *logEdit;
    QLabel      *statusLabel;
};

#endif // MAINWINDOW_H

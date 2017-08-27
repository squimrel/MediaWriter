TEMPLATE = app

QT += core

LIBS += -lcheckisomd5 -limplantisomd5
PKGCONFIG += isomd5sum

CONFIG += c++11
CONFIG += console
CONFIG += link_pkgconfig

TARGET = helper
DESTDIR = ../app/

include($$top_srcdir/deployment.pri)

target.path = $$LIBEXECDIR
INSTALLS += target

SOURCES = main.cpp genericdrive.cpp write.cpp

HEADERS += genericdrive.h write.h

linux {
    include(linux/linux.pri)
}
win32 {
    include(win/win.pri)
}
macx {
    include(mac/mac.pri)
}

RESOURCES += ../translations/translations.qrc

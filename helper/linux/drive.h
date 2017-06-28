/*
 * Fedora Media Writer
 * Copyright (C) 2016 Martin Bříza <mbriza@redhat.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#ifndef DRIVE_H
#define DRIVE_H

#include <memory>
#include <utility>

#include <QDBusInterface>
#include <QDBusUnixFileDescriptor>
#include <QString>
#include <QTextStream>
#include <QtGlobal>

class Drive {
public:
    /**
     * Shared public interface across platforms.
     */
    Drive(const QString &driveIdentifier);
    void open();
    void close();
    void write(const void *buffer, std::size_t size);
    int getDescriptor() const;
    void wipe();
    QPair<QString, qint64> addPartition(quint64 offset = 0ULL, const QString &label = "");
    QString mount(const QString &partitionIdentifier);
    void umount();

private:
    QDBusUnixFileDescriptor m_fileDescriptor;
    QString m_identifier;
    std::unique_ptr<QDBusInterface> m_device;
    QString m_path;
};

#endif // DRIVE_H

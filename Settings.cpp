/*
 * Copyright (c) 2022, Filiph Sandström <filiph.sandstrom@filfatstudios.com>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#include "Settings.h"

namespace Browser {

Settings::Settings()
{
    m_qsettings = new QSettings("Serenity", "Ladybird");
}

QString Settings::homepage()
{
    return m_qsettings->value("homepage", "https://www.serenityos.org/").toString();
}
void Settings::set_homepage(QString const& homepage)
{
    m_qsettings->setValue("homepage", homepage);
}

bool Settings::hide_tabs()
{
    return m_qsettings->value("hide_tabs", true).toBool();
}
void Settings::set_hide_tabs(bool const& hide_tabs)
{
    m_qsettings->setValue("hide_tabs", hide_tabs);
}

}

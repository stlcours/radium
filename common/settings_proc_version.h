/* Copyright 2012 Kjetil S. Matheussen

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. */


#ifndef SETTINGS_PROC_H
#define SETTINGS_PROC_H

#define ANY_VERSION -1.0

extern LANGSPEC bool SETTINGS_read_bool(const char *key, bool def, double version);
extern LANGSPEC int64_t SETTINGS_read_int(const char *key, int64_t def, double version);
extern LANGSPEC double SETTINGS_read_double(const char *key, double def, double version);
extern LANGSPEC const char *SETTINGS_read_string(const char *key, const char *def, double version);
extern LANGSPEC void SETTINGS_write_bool(const char *key, bool val);
extern LANGSPEC void SETTINGS_write_int(const char *key, int64_t val);
extern LANGSPEC void SETTINGS_write_double(const char *key, double val);
extern LANGSPEC void SETTINGS_write_string(const char *key, const char *val);

#endif

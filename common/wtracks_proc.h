/* Copyright 2000 Kjetil S. Matheussen

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

#ifndef _RADIUM_COMMON_WTRACKS_PROC_H
#define _RADIUM_COMMON_WTRACKS_PROC_H

static inline int WTRACK_fxtrack_width(const int fontwidth){
  return (3 * fontwidth) + 2;
}

extern LANGSPEC int WTRACK_num_non_polyphonic_subtracks(const struct WTracks *wtrack);

static inline int WTRACK_num_subtracks(const struct WTracks *wtrack){
  return WTRACK_num_non_polyphonic_subtracks(wtrack) + wtrack->track->polyphony;
}

static inline int NOTE_subtrack(const struct WTracks *wtrack, const struct Notes *note){
  return WTRACK_num_non_polyphonic_subtracks(wtrack) + note->polyphony_num;
}


extern LANGSPEC int WTRACK_getWidth(
                    struct Tracker_Windows *window,
                    struct WTracks *wtrack
                    );

extern LANGSPEC struct WTracks *WTRACK_new(void);

extern LANGSPEC void CloseWTrack(struct WBlocks *wblock, NInt wtracknum);

extern LANGSPEC void CloseAllWTracks(struct WBlocks *wblock);

extern LANGSPEC void UpdateWTracks(struct Tracker_Windows *window, struct WBlocks *wblock);

extern LANGSPEC void UpdateWTracksCoordinates(
	struct Tracker_Windows *window,
	struct WBlocks *wblock
);

/*
extern LANGSPEC struct WTracks *UpdateWTrackCoordinates(
	struct Tracker_Windows *window,
	struct WBlocks *wblock,
	struct WTracks *wtrack,
	int wtrack_notearea_x
);
*/

extern LANGSPEC void UpdateAllWTracksCoordinates(
	struct Tracker_Windows *window,
	struct WBlocks *wblock
);


extern LANGSPEC void UpdateAndClearSomeTrackReallinesAndGfxWTracks(
	struct Tracker_Windows *window,
	struct WBlocks *wblock,
	NInt starttrack,
	NInt endtrack
);


extern LANGSPEC void ChangeNoteLength_CurrPos(
	struct Tracker_Windows *window
);

extern LANGSPEC void ChangeNoteLength_Block_CurrPos(
	struct Tracker_Windows *window
);

extern LANGSPEC void ChangeNoteAreaWidth_CurrPos(
                                 struct Tracker_Windows *window
                                 );

extern LANGSPEC void ChangeNoteAreaWidth_Block_CurrPos(
                                       struct Tracker_Windows *window
                                       );
  
extern LANGSPEC void MinimizeTrack_CurrPos(
	struct Tracker_Windows *window
);

extern LANGSPEC void MinimizeBlock_CurrPos(
	struct Tracker_Windows *window
);

extern LANGSPEC void SwapTrack_CurrPos(
	struct Tracker_Windows *window
);

extern LANGSPEC void AppendWTrack_CurrPos(struct Tracker_Windows *window, struct WBlocks *wblock);

extern LANGSPEC int WTRACK_getx1(
	struct Tracker_Windows *window,
	struct WBlocks *wblock,
	NInt track
);

extern LANGSPEC int WTRACK_getx2(
	struct Tracker_Windows *window,
	struct WBlocks *wblock,
	NInt track
);

extern LANGSPEC struct WTracks *WTRACK_get(struct WBlocks *wblock, int x);

#endif

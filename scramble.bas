'======================================================================================================================================================================================================
' SCRAMBLE
'------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
' Programmed by RokCoder
'------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
' Scramble is a side-scrolling shooter game released for arcades in 1981. It was developed by Konami, and manufactured and distributed by Leijac in Japan and Stern in North America.
' It was the first side-scrolling shooter with forced scrolling and multiple distinct levels, serving as a foundation for later side-scrolling shooters.
'
' This version is a tribute to the original programmed using QB64PE
'------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
' V0.1 - 26/02/2023 - First release
'------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
' https://github.com/rokcoder-qb64/scramble
'------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
' https://www.rokcoder.com
' https://www.github.com/rokcoder
' https://www.facebook.com/rokcoder
' https://www.youtube.com/rokcoder
'======================================================================================================================================================================================================

$VERSIONINFO:CompanyName=RokSoft
$VERSIONINFO:FileDescription=QB64 Scramble
$VERSIONINFO:InternalName=scramble.exe
$VERSIONINFO:ProductName=QB64 Scramble
$VERSIONINFO:OriginalFilename=scramble.exe
$VERSIONINFO:LegalCopyright=(c)2023 RokSoft
$VERSIONINFO:FILEVERSION#=0,1,0,0
$VERSIONINFO:PRODUCTVERSION#=0,1,0,0
$EXEICON:'./assets/scramble.ico'

'======================================================================================================================================================================================================

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

'======================================================================================================================================================================================================

CONST FALSE = 0
CONST TRUE = NOT FALSE

CONST SCREEN_WIDTH = 224 ' Resolution of the original arcade game - changing this to 448 (for example) should give a fuly playable version in a more widescreen mode
CONST SCREEN_HEIGHT = 256
CONST NUM_STAGES = 6 ' Scramble has six distinct stages
CONST TILE_WIDTH = 8 ' All graphics are based on 8x8 pixel tiles
CONST TILE_HEIGHT = 8
CONST NUM_COLUMNS = INT(SCREEN_WIDTH / TILE_WIDTH) ' Used primarily for displayuing the landscape
CONST NUM_ROWS = 25 ' This is the number of (8 pixel) rows in the actual gaming area (not including HUD)
CONST GAME_HEIGHT = NUM_ROWS * TILE_HEIGHT

CONST KEYDOWN_LEFT = 19200 ' Scan codes for the keys
CONST KEYDOWN_RIGHT = 19712
CONST KEYDOWN_UP = 18432
CONST KEYDOWN_DOWN = 20480
CONST KEYDOWN_FIRE = 97
CONST KEYDOWN_BOMB = 122

CONST PLAYER_FLYING = 0 ' States for the player
CONST PLAYER_EXPLODING = 1
CONST PLAYER_SPAWNING = 2

CONST PLAYER_WIDTH = 32 ' Dimensions of the player's sprite
CONST PLAYER_HEIGHT = 16

CONST MAX_FUEL = 112 ' Quantity of fuel that the player can carry
CONST INITIAL_FUEL_SPEED = 20 ' Initial setting reduces fuel by one every INITIAL_FUEL_SPEED frames
CONST DELTA_FUEL_SPEED_PER_PASS = 2 ' After completing all six stages, the speed at which fuel goes down is increased

CONST TYPE_MISSILE = 0 ' Different object types
CONST TYPE_FUEL = 1
CONST TYPE_MYSTERY = 2
CONST TYPE_BASE = 3
CONST TYPE_METEOR = 4
CONST TYPE_UFO = 5

CONST SPRITE_ROCKET = 0 ' Different sprites available in the game
CONST SPRITE_FUEL = 1
CONST SPRITE_MYSTERY = 2
CONST SPRITE_BASE = 3
CONST SPRITE_METEOR = 4
CONST SPRITE_UFO = 5
CONST SPRITE_PLAYER = 6
CONST SPRITE_PLAYER_EXPLOSION = 7
CONST SPRITE_BOMB = 8
CONST SPRITE_BOMB_EXPLOSION = 9
CONST SPRITE_UFO_EXPLOSION = 10
CONST SPRITE_LIVE = 11
CONST SPRITE_LEVEL_FLAG = 12
CONST SPRITE_MYSTERY_SCORE = 13
CONST SPRITE_OBJECT_EXPLOSION = 14
CONST SPRITE_TERRAIN = 15
CONST SPRITE_FUEL_BAR = 16
CONST SPRITE_STAGE = 17
CONST SPRITE_BULLET = 18
CONST SPRITE_TEXT = 19

CONST AMMO_BULLET = SPRITE_BULLET ' Pulling out the ammo types for code clarity
CONST AMMO_BOMB = SPRITE_BOMB

CONST SFX_LASER = 0 ' All available sound effects
CONST SFX_FUEL_WARNING = 1
CONST SFX_SMALL_EXPLOSION = 2
CONST SFX_ENGINE = 3
CONST SFX_ROCKET_EXPLOSION = 4
CONST SFX_BOMB = 5
CONST SFX_START_GAME = 6
CONST SFX_EXPLOSION = 7

CONST text$ = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789?c.- " ' Available font characters

CONST TEXT_WHITE = 0 ' Text is stored in five colours in the sprite sheet (for simplicity)
CONST TEXT_RED = 1
CONST TEXT_BLUE = 2
CONST TEXT_YELLOW = 3
CONST TEXT_PURPLE = 4

CONST STATE_TITLE = 0 ' Different game states used in the game
CONST STATE_HIGHSCORES = 1
CONST STATE_SCORETABLE = 2
CONST STATE_DEMO = 3
CONST STATE_STARTING_GAME = 4
CONST STATE_PLAY = 5
CONST STATE_GAME_OVER = 6
CONST STATE_REACHED_BASE = 7

'======================================================================================================================================================================================================

TYPE POINT
    x AS INTEGER
    y AS INTEGER
END TYPE

TYPE RECT
    x AS INTEGER ' Left
    y AS INTEGER ' Top
    w AS INTEGER ' Width
    h AS INTEGER ' Height
    cx AS INTEGER ' Centre x
    cy AS INTEGER ' Centre y
END TYPE

TYPE SPRITE
    spriteId AS INTEGER ' SPRITE_* id
    position AS POINT
    frame AS INTEGER ' For sprites with multiple frames of animation
    counter AS INTEGER ' Generic counter
END TYPE

TYPE SPRITEDATA ' One entry for each SPRITE_*
    offset AS INTEGER ' Offset into sprite list for this sprite's first frame of animation
    size AS POINT
    hitbox AS RECT ' This is as good as it gets - 1980's arcade games really don't want or need per pixel collision! We want a little leniency on player collisions at the very least!
END TYPE

TYPE PLAYER
    sprite AS SPRITE ' Player sprite
    state AS INTEGER ' PLAYER_* state
    fuel AS INTEGER ' Amount of fuel remaining
    fuelCounter AS INTEGER ' Frame counter as fuel goes down by one every fuelSpeed frames
    fuelSpeed AS INTEGER ' Rate of fuel usage
    firePause AS INTEGER ' Slight minimum delay between bullets
    firePressed AS INTEGER ' Flag used to prevent constant bullets when fire button held down
    bombPause AS INTEGER ' Slight minimum delay between bombs
    bombPressed AS INTEGER ' Flag used to prevent constant bombs when bomb button held down
END TYPE

TYPE OBJECT ' Used for every game object (other than player)
    sprite AS SPRITE
    inFlight AS INTEGER ' Specific to missiles but sits in this structure because we're lacking virtuals in QB64
END TYPE

TYPE GAME
    frameCounter AS LONG
    fps AS INTEGER
    dataIndex AS INTEGER ' Index into the BIN file containing all landscape and enemy positioning data
    columnIndex AS INTEGER ' This is more of a toggle really, alternating between zero and one for each column displayed on the screen - used for landscape tiling effect on higher stages
    stage AS INTEGER ' Current game stage (0 to 5)
    currentPalette AS INTEGER ' The palette being used (0 to 7)
    progressPalette AS INTEGER ' Palettes change as you progress through each stage - this is the counter used to trigger each change
    score AS INTEGER
    hiscore AS INTEGER
    lives AS INTEGER
    scrollOffset AS INTEGER ' How far into the current stage the player is (in pixels)
    state AS INTEGER ' STATE_* game state
    highlightScore AS INTEGER ' We highlight a score on the high score table if the player has achieved it in the last game
    baseDestroyed AS INTEGER ' You need to destroy the base on stage 6 to actually complete that stage
    flagCount AS INTEGER ' Number of times all six stages have been completed in a game
END TYPE

TYPE COLUMN
    texture AS LONG ' Texture handle
    top AS INTEGER ' Row for top column (for collisions)
    bottom AS INTEGER ' Row for bottom column (for collisions)
END TYPE

TYPE STARS ' As in the arcade version, there are four constant star background (the first always displays and the other three cycle)
    sprite0 AS LONG
    sprite1 AS LONG
    sprite2 AS LONG
    sprite3 AS LONG
    frame AS INTEGER ' The frame that is being displayed (in addition to the first)
    counter AS INTEGER ' Counter the determines when to change the frame being displayed
END TYPE

'======================================================================================================================================================================================================

' Not a fan of globals but this is QB64 so what can you do?

DIM SHARED spriteSheet& ' Handle to sprite sheet
DIM SHARED virtualScreen& ' Handle to virtual screen which is drawn to and then blitted/stretched to the main display
DIM SHARED mapData$ ' The binary game data (landscape, alien positions, etc) is loaded as a string of characters
DIM SHARED game AS GAME ' General game data
DIM SHARED spriteData(64) AS SPRITEDATA ' Every defined SPRITE_* type has corresponding data
DIM SHARED stageDataOffset%(6) ' Offset into mapData$ for the beginning of each stage
DIM SHARED column(NUM_COLUMNS + 1) AS COLUMN ' Each landscape column is rendered to a texture as it appears on screen - one extra column to allow smoth scrolling onto (and off) screen
DIM SHARED ammo(32) AS SPRITE ' Sprites for bombs and missiles
DIM SHARED ammoCount% ' Current ammount of ammo on the screen at any given point
DIM SHARED object(16) AS OBJECT ' Stores TYPE_* objects that are currently on screen (missiles, ufos, etc)
DIM SHARED objectCount% ' Number of objects currently on screen
DIM SHARED player AS PLAYER
DIM SHARED pal&(8, 4), gPal%(4) ' There are eight four-colour palettes that control the colours of objects and landscape; gPal% contains the indexes of the colours in the palettes that are to be updated
DIM SHARED tileU%(27), tileV%(27) ' Coordinates in sprite sheet for the various landscape parts
DIM SHARED paletteOrder%(7) ' The order in which the palette is updated to match the arcade game (which doesn't use all eight palettes)
DIM SHARED spawnedSprite(32) AS SPRITE ' Explosions, mystery scores and any other sprite that is spawned ad hoc
DIM SHARED spawnedSpriteCount%
DIM SHARED spriteUV(320) AS POINT ' The texture coordinates for every animation frame of every sprite in the sprite sheet
DIM SHARED sfx&(8) ' Sound effects handles
DIM SHARED stars AS STARS
DIM SHARED playerExplosionFrameOrder%(7) ' So we play the animation frames in the same order as the arcade game
DIM SHARED place$(10) ' Strigs for 1ST, 2ND, 3RD, etc for high score table
DIM SHARED placeColour%(10) ' The colours to desplay the scores on the high score table
DIM SHARED scoreTable$(6) ' The strings for displaying on the attrack loop (for scores of each object type)
DIM SHARED hiscores%(10) ' The top ten high scores

'===== Game loop ======================================================================================================================================================================================

PrepareScramble

DO: _LIMIT (game.fps%)
    UpdateFrame
    RenderFrame
LOOP

'===== Error handling =================================================================================================================================================================================

fileReadError:
InitialiseHiscores
RESUME NEXT

fileWriteError:
ON ERROR GOTO 0
RESUME NEXT

'===== One time initialisations =======================================================================================================================================================================

SUB PrepareScramble
    DIM m%, i%
    m% = INT((_DESKTOPHEIGHT - 80) / SCREEN_HEIGHT) ' Ratio for how much we can scale the game up (integer values) whilst still fitting vertically on the screen
    virtualScreen& = _NEWIMAGE(SCREEN_WIDTH, SCREEN_HEIGHT, 256) ' This is the same resolution as the original arcade game
    FOR i% = 0 TO NUM_COLUMNS
        column(i%).texture& = _NEWIMAGE(TILE_WIDTH, SCREEN_HEIGHT, 256) ' The landscape strips are rendered to their own sprites
        _CLEARCOLOR _RGB(0, 0, 0), column(i%).texture& ' and those sprites set black to be transparent
    NEXT i%
    SCREEN _NEWIMAGE(SCREEN_WIDTH * m%, SCREEN_HEIGHT * m%, 256) ' The screen we ultimately display is the defined size multiplied by a ratio as determined above
    _DELAY 0.5
    _SCREENMOVE _MIDDLE
    '$RESIZE:STRETCH
    _ALLOWFULLSCREEN _SQUAREPIXELS , _SMOOTH
    _TITLE "Scramble"
    _DEST virtualScreen&
    game.fps% = 60 ' 60 frames per second
    RANDOMIZE TIMER
    game.frameCounter& = 0
    spriteSheet& = LoadImage&("sprite-sheet") ' Load up the main sprite sheet with black as transparency
    _CLEARCOLOR _RGB(0, 0, 0), spriteSheet&
    stars.sprite0& = LoadImage&("stars-1") ' Load up the background star sprites (with black as transparency on all but the first)
    stars.sprite1& = LoadImage&("stars-2")
    stars.sprite2& = LoadImage&("stars-3")
    stars.sprite3& = LoadImage&("stars-4")
    _CLEARCOLOR _RGB(0, 0, 0), stars.sprite1&
    _CLEARCOLOR _RGB(0, 0, 0), stars.sprite2&
    _CLEARCOLOR _RGB(0, 0, 0), stars.sprite3&
    stars.frame% = 1 ' We cycle through the star frames (though the first one is always displayed)
    LoadDataFromROM ' Load the bin file that contains all the data for the terrain and enemy positions
    PrepareSprites ' Initialise various structures so we can easily address the sprites and their frames from the sprite sheet
    ExtractPalettes ' We pull the palettes from samples stored in the sprite sheet itself
    ReadData ' Initialising various arrays from data statements
    InitialiseStageDataOffset ' Working out offsets into data for the start of each f the six stages
    LoadAllSFX
    ReadHiscores ' Read high scores from file (or create them if the file doesn't exist or can't be read)
    game.highlightScore% = -1 ' If we've just made a high score then this is the index to its position in the high score table
    game.hiscore% = hiscores%(0) ' The current high score is the highest score in the table we've just read
    SetGameState STATE_TITLE ' Set the game state in its initial state
END SUB

SUB PrepareSprites

    ' A little info on how the sprites are unpacked into the data
    '
    ' Calling SetSpriteDataWithHitBox and SetSpriteData set the width and height of the sprite, the hit box if applicable and the index into the sprite list where this sprite has its first frame
    ' Calling AddSpriteStrip sets up the positions in the sprite sheet for all frames of this particular sprite. It also increases the index by that number of frames
    ' As an example, SPRITE_PLAYER sets the size to 32x16 and the hitbox between coordinates (6,2) and (26,12) - the current frame index is also stored into the spreite data (which is zero at this point)
    ' The four frames for the player are then read into the spriteUV list (with UV being the coordinates into the sprite sheet where they appear)
    ' The function also increases the frame index by that many frames (four in the case) so the next sprite knows the spriteUVs for it will start at an offset of 4

    DIM i%, c%
    i% = 0
    SetSpriteDataWithHitbox SPRITE_PLAYER, i%, 32, 16, 6, 2, 26, 12 ' Player sprite is 32x16 in size and has a hit box from coordinates (6,2) to (26,12) and its first sprite frame is at index 0 in spriteUV array
    AddSpriteStrip i%, 1, 7, 4, 0, 18 ' First player sprite is at (1,7) in the sprite sheet, there are 4 frames of animation and the distance between each in the sprite sheet is (0,18) - i% automatically increases by 4
    SetSpriteData SPRITE_PLAYER_EXPLOSION, i%, 32, 16
    AddSpriteStrip i%, 69, 7, 4, 0, 18
    SetSpriteDataWithHitbox SPRITE_BOMB, i%, 16, 16, 6, 6, 4, 4
    AddSpriteStrip i%, 103, 7, 5, 0, 18
    SetSpriteData SPRITE_BOMB_EXPLOSION, i%, 16, 16
    AddSpriteStrip i%, 121, 7, 4, 0, 18
    SetSpriteData SPRITE_UFO_EXPLOSION, i%, 16, 16
    AddSpriteStrip i%, 139, 7, 4, 0, 18
    SetSpriteDataWithHitbox SPRITE_METEOR, i%, 16, 16, 0, 3, 16, 10
    AddSpriteStrip i%, 157, 7, 4, 0, 18
    SetSpriteData SPRITE_LIVE, i%, 16, 8
    AddSpriteStrip i%, 1, 78, 1, 0, 0
    SetSpriteData SPRITE_LEVEL_FLAG, i%, 8, 8
    AddSpriteStrip i%, 19, 78, 1, 0, 0
    SetSpriteDataWithHitbox SPRITE_UFO, i%, 16, 16, 2, 4, 12, 8
    AddSpriteStrip i%, 121, 79, 1, 0, 0
    SetSpriteDataWithHitbox SPRITE_ROCKET, i%, 16, 16, 4, 0, 8, 16
    AddSpriteStrip i%, 1, 97, 3, 0, 18
    SetSpriteDataWithHitbox SPRITE_BASE, i%, 16, 16, 0, 0, 16, 16
    AddSpriteStrip i%, 37, 97, 3, 0, 18
    SetSpriteData SPRITE_MYSTERY_SCORE, i%, 16, 16
    AddSpriteStrip i%, 73, 97, 3, 0, 18
    SetSpriteDataWithHitbox SPRITE_MYSTERY, i%, 16, 16, 0, 0, 16, 16
    AddSpriteStrip i%, 91, 97, 1, 0, 0
    SetSpriteDataWithHitbox SPRITE_FUEL, i%, 16, 16, 0, 0, 16, 16
    AddSpriteStrip i%, 91, 115, 1, 0, 0
    SetSpriteData SPRITE_OBJECT_EXPLOSION, i%, 16, 16
    AddSpriteStrip i%, 109, 97, 3, 0, 18 ' Spriate strips aren't always consecutive in the sprite sheet - we can simply load multiple strips
    AddSpriteStrip i%, 91, 133, 1, 0, 0
    SetSpriteData SPRITE_TERRAIN, i%, 8, 8
    AddSpriteStrip i%, 1, 151, 17, 10, 0
    AddSpriteStrip i%, 1, 161, 17, 10, 0
    SetSpriteData SPRITE_FUEL_BAR, i%, 8, 8
    AddSpriteStrip i%, 1, 171, 9, 10, 0
    SetSpriteData SPRITE_STAGE, i%, 32, 8
    AddSpriteStrip i%, 1, 191, 1, 0, 0
    AddSpriteStrip i%, 1, 181, 4, 32, 0
    AddSpriteStrip i%, 35, 191, 1, 0, 0
    AddSpriteStrip i%, 131, 181, 2, 34, 0
    SetSpriteDataWithHitbox SPRITE_BULLET, i%, 8, 8, 3, 3, 2, 2
    AddSpriteStrip i%, 181, 201, 1, 0, 0
    SetSpriteData SPRITE_TEXT, i%, 8, 8
    FOR c% = 0 TO 4 ' The frames for text sprites include white, red, blue, yellow and purple fonts
        AddSpriteStrip i%, 91, 201 + c% * 30, 9, 9, 0
        AddSpriteStrip i%, 1, 210 + c% * 30, 17, 9, 0
        AddSpriteStrip i%, 1, 201 + c% * 30, 10, 9, 0
        AddSpriteStrip i%, 1, 220 + c% * 30, 1, 9, 0
        AddSpriteStrip i%, 172, 201 + c% * 30, 2, 9, 0
        AddSpriteStrip i%, 154, 210 + c% * 30, 2, 9, 0
    NEXT c%
END SUB

' SetSpriteBasics ( SPRITE id, Offset into UV sprite data for first animation frame of this sprite, sprite width, sprite height )
' - Data required for every sprite type listed in the SPRITE_* definitions
SUB SetSpriteBasics (s%, i%, sw%, sh%)
    spriteData(s%).offset% = i%
    spriteData(s%).size.x% = sw%
    spriteData(s%).size.y% = sh%
END SUB

' SetSpriteData ( SPRITE id, Offset into UV sprite data for first animation frame of this sprite, sprite width, sprite height )
' - Sets up a sprite with a bounding box the same as the sprite's dimensions
SUB SetSpriteData (s%, i%, sw%, sh%)
    SetSpriteBasics s%, i%, sw%, sh%
    SetRect spriteData(s%).hitbox, 0, 0, sw%, sh%
END SUB

' SetSpriteDataWithHitbox ( SPRITE id, Offset into UV sprite data for first animation frame of this sprite, sprite width and height, bounding box coordinates, width and height )
' - Sets up a sprite with a defined bounding box
SUB SetSpriteDataWithHitbox (s%, i%, sw%, sh%, x%, y%, w%, h%)
    SetSpriteBasics s%, i%, sw%, sh%
    SetRect spriteData(s%).hitbox, x%, y%, w%, h%
END SUB

' AddSpriteStrip ( Offset into UV sprite data, UV coordinate offset into sprite sheet for first of sprite's frames, number of sprite frames to read, delta values between consecutive sprite frames )
' - Adds to the UV sprite data list (and updates the index that was passed in so that it is set to the next undefined UV in the array upon return)
SUB AddSpriteStrip (spriteIndex%, u%, v%, n%, du%, dv%)
    DIM i%
    FOR i% = 1 TO n%
        spriteUV(spriteIndex%).x% = u%
        spriteUV(spriteIndex%).y% = v%
        u% = u% + du%
        v% = v% + dv%
        spriteIndex% = spriteIndex% + 1
    NEXT i%
END SUB

' ExtractPalettes
' - Certain sprites (includng landscape) are palette based and use specific palette entries that are updated throughout game play
'   This function reads the eight sets of four colours that are used in addition to extracting the fpir (grey colour) palette indexes that need to be updated with these target colours
SUB ExtractPalettes
    DIM i%, x%, y%
    _SOURCE spriteSheet&
    i% = 0
    FOR y% = 1 TO 4
        FOR x% = 0 TO 7
            pal&(INT(i% / 4), i% MOD 4) = _PALETTECOLOR(POINT(127 + x% * 4, 97 + y% * 4), spriteSheet&)
            i% = i% + 1
        NEXT x%
    NEXT y%
    i% = 0
    FOR x% = 0 TO 3
        gPal%(i%) = POINT(127 + x% * 4, 97)
        i% = i% + 1
    NEXT x%
END SUB

SUB ReadData
    DIM i%
    FOR i% = 0 TO 27: READ tileU%(i%): NEXT i% ' UV coordinates in sprite sheet for each terrain tile
    FOR i% = 0 TO 27: READ tileV%(i%): NEXT i%
    FOR i% = 0 TO 6: READ paletteOrder%(i%): NEXT i% ' The order we modify the palettes to to mimic the arcade game (basically missing one single palette out)
    FOR i% = 0 TO 6: READ playerExplosionFrameOrder%(i%): NEXT i% ' The order to player the player's explosion animation frames
    FOR i% = 0 TO 9: READ place$(i%): NEXT i% ' Strings for the high score table
    FOR i% = 0 TO 9: READ placeColour%(i%): NEXT i% ' Text colours to display the positions in the high score table
    FOR i% = 0 TO 5: READ scoreTable$(i%): NEXT i% ' Strings for the attract mode score information page
    DATA 161,11,31,1,21,51,71,41,61,91,111,81,101,131,141,121,151,161,151,1,91,101,71,91,121,141,111,131
    DATA 161,151,151,151,151,151,151,151,151,151,151,151,151,151,151,151,151,151,161,161,161,161,161,161,161,161,161,161
    DATA 0,1,3,4,5,6,7
    DATA 0,1,0,1,0,2,3
    DATA "1ST","2ND","3RD","4TH","5TH","6TH","7TH","8TH","9TH","10TH"
    DATA 3,3,3,2,2,2,4,4,4,4
    DATA " ...  50 PTS     "," ...  80 PTS     "," ... 100 PTS     "," ... 150 PTS     "," ... 800 PTS     "," ... MYSTERY"
END SUB

' LoadDataFromROM
' - This is original ROM data holding the terrain details and the positioning of the enemy objects
'   I'm loading it as a text string (with each character being between ASCII 0 and ASCII 255)
SUB LoadDataFromROM
    DIM handle&
    handle& = FREEFILE
    OPEN "assets/game-data.bin" FOR BINARY AS #handle& LEN = 1
    mapData$ = SPACE$(LOF(handle&))
    GET #handle&, , mapData$
    CLOSE #handle&
END SUB

'===== High score code ================================================================================================================================================================================

' ReadHiscores
' - Read high scores from local storage (with fallback to initialising data if there's an error while reading the file for any reason)
SUB ReadHiscores
    DIM i%, handle&
    ON ERROR GOTO fileReadError
    IF NOT _FILEEXISTS("scores.txt") THEN InitialiseHiscores: EXIT SUB
    handle& = FREEFILE
    OPEN "scores.txt" FOR INPUT AS #handle&
    FOR i% = 0 TO 9
        INPUT #handle&, hiscores%(i%)
    NEXT i%
    CLOSE #handle&
    ON ERROR GOTO 0
END SUB

' InitialiseHiscores
' - Set up default high score values
SUB InitialiseHiscores
    DIM i%
    FOR i% = 0 TO 9
        hiscores%(i%) = (10 - i%) * 1000
    NEXT i%
END SUB

' WriteHiscores
' - Store high scores to local storage (trapping any errors that might occur - write-protected, out of space, etc)
SUB WriteHiscores
    DIM i%, handle&
    ON ERROR GOTO fileWriteError
    handle& = FREEFILE
    OPEN "scores.txt" FOR OUTPUT AS #handle&
    FOR i% = 0 TO 9
        PRINT #handle&, hiscores%(i%)
    NEXT i%
    CLOSE #handle&
    ON ERROR GOTO 0
END SUB

'===== Frame update functions =========================================================================================================================================================================

SUB UpdateFrame
    UpdateStars ' Whatever stage we're at, the stars always update
    SELECT CASE game.state%
        CASE STATE_TITLE ' Title state is maintained for 8 seconds
            IF game.frameCounter& > 8 * game.fps% THEN SetGameState STATE_HIGHSCORES
        CASE STATE_HIGHSCORES ' High scores are displayed for 8 seconds
            IF game.frameCounter& > 8 * game.fps% THEN SetGameState STATE_SCORETABLE
        CASE STATE_SCORETABLE ' Attract loop's score information is displayed for 8 seconds
            IF game.frameCounter& > 8 * game.fps% THEN PrepareForLevel: game.lives% = 1: SetGameState STATE_DEMO
        CASE STATE_DEMO ' Very similar to game play except if reverts to title state after losing a life (and player input is ignored)
            IF player.state% = PLAYER_FLYING THEN UpdateScroll
            UpdateObjects
            UpdatePlayer
            UpdateAmmo
            UpdateSpawnedSprites
            CalculateCollisions game.scrollOffset%
            IF LifeLost% THEN SetGameState STATE_TITLE
        CASE STATE_STARTING_GAME ' Ywo and a half second pause while intro string is displayed and start music jingles merrily away
            IF game.frameCounter& > 2.5 * game.fps% THEN SetGameState STATE_PLAY
        CASE STATE_PLAY ' Main game state
            IF player.state% = PLAYER_FLYING THEN UpdateScroll
            UpdateObjects
            UpdatePlayer
            UpdateAmmo
            UpdateSpawnedSprites
            CalculateCollisions game.scrollOffset%
            IF LifeLost% THEN
                IF game.lives% = 0 THEN SetGameState STATE_GAME_OVER ELSE PrepareForLevel ' If we've lost a life and have no lives left then it's all over - otherwise restart the current stage
            END IF
            IF game.stage% = 5 THEN ' There are two chances at destroying the enemy base - the level ends earlier if you destroy the first attempt
                IF (game.dataIndex% = LEN(mapData$) + 150 AND game.baseDestroyed%) OR game.dataIndex% = 2 * LEN(mapData$) - stageDataOffset%(game.stage%) + 150 THEN SetGameState STATE_REACHED_BASE
            END IF
        CASE STATE_GAME_OVER ' Game over is displayed for 2 seconds
            IF game.frameCounter& > 2 * game.fps% THEN SetGameState STATE_HIGHSCORES
        CASE STATE_REACHED_BASE ' We're either displaying success or failure here for 3 seconds before either going back to first stage or retrying the final stage
            IF game.frameCounter& > 3 * game.fps% THEN
                SetGameState STATE_PLAY
                IF game.baseDestroyed% THEN BaseDefeated ELSE PrepareForLevel
            END IF
    END SELECT
END SUB

SUB UpdateScroll
    DIM i%
    game.scrollOffset% = game.scrollOffset% + 1 ' How far into the current stage we are (in pixels)
    IF (game.scrollOffset% AND 7) = 0 THEN UpdateLandscape ' The terrain is tile based so we only need to load in a new column every 8 pixels
    FOR i% = 0 TO objectCount% - 1: object(i%).sprite.position.x% = object(i%).sprite.position.x% - 1: NEXT i% ' All enemy objects move one pixels to the left
    FOR i% = 0 TO spawnedSpriteCount% - 1: spawnedSprite(i%).position.x% = spawnedSprite(i%).position.x% - 1: NEXT i% ' All spawned sprites move one pixel to the left
END SUB

SUB UpdateFromVirtualScreen
    game.frameCounter& = game.frameCounter& + 1 ' Increase the frame counter which can be used for any frame-related calculations such as pauses or animation updates
    _PUTIMAGE , virtualScreen&, 0, (0, 0)-(SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1) ' Copy from virtual screen to target screen which allows for automatic upscaling
    _DISPLAY
END SUB

'===== Frame render functions =========================================================================================================================================================================

SUB RenderFrame
    RenderStars ' Stars are rendered every frame
    SELECT CASE game.state%
        CASE STATE_TITLE
            RenderTitle
            RenderStartKey
        CASE STATE_HIGHSCORES
            RenderHighscores
            RenderStartKey
        CASE STATE_SCORETABLE
            RenderScoreTable
            RenderStartKey
        CASE STATE_DEMO
            RenderLandscape game.scrollOffset%
            RenderObjects
            RenderPlayer
            RenderAmmo
            RenderSpawnedSprites
            RenderHud
            RenderStartKey
        CASE STATE_STARTING_GAME
            RenderStartingGame
        CASE STATE_PLAY
            RenderLandscape game.scrollOffset%
            RenderObjects
            RenderPlayer
            RenderAmmo
            RenderSpawnedSprites
            RenderHud
        CASE STATE_GAME_OVER
            RenderGameOver
        CASE STATE_REACHED_BASE
            RenderReachedBase
    END SELECT
    UpdateFromVirtualScreen ' Update from virtual screen to actual screen here
END SUB

' RenderSpawnedSprites
' - Explosions, mystery scores and any other sprites that have been created in an ad hoc manner
SUB RenderSpawnedSprites
    DIM i%
    FOR i% = spawnedSpriteCount% - 1 TO 0 STEP -1
        RenderSprite spawnedSprite(i%), 40
    NEXT i%
END SUB

SUB RenderHud
    DIM i%, d%
    LINE (0, 0)-(SCREEN_WIDTH - 1, 39), 0, BF ' Clear top section of screen (above game play)
    LINE (0, 240)-(SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1), 0, BF ' Clear section of screen below game play
    RenderScore
    FOR i% = 0 TO 5
        RenderImage SPRITE_STAGE, i%, 16 + i% * 32, 24 ' Frames 0 to 5 of SPRITE_STAGE are the empty boxes displayed for each stage progression in the HUD
        RenderImage SPRITE_STAGE, 6 - (i% <= game.stage%), 16 + i% * 32, 32 ' Bit of logic relying on TRUE equating to -1 to determine whether we use frame 6 or 7 of SPRITE_STAGE to fill each box
    NEXT i%
    RenderText 3, 30, "FUEL", TEXT_YELLOW
    FOR i% = 0 TO game.lives% - 1
        RenderImage SPRITE_LIVE, 0, 16 * i%, 248
    NEXT i%
    FOR i% = 0 TO game.flagCount% - 1
        RenderImage SPRITE_LEVEL_FLAG, 0, 216 - 8 * i%, 248 ' These flags show how many times you've gone through all six stages in this game
    NEXT i%
    FOR i% = 0 TO MAX_FUEL / 8 - 1
        d% = player.fuel% - i% * 8
        IF d% < 0 THEN d% = 0 ELSE IF d% > 8 THEN d% = 8
        RenderImage SPRITE_FUEL_BAR, 8 - d%, 64 + 8 * i%, 240 ' d% is used to ensure the final section of the fuel bar shows the correct amount of fuel (as opposed to a solid 8-pixel block)
    NEXT i%
END SUB

SUB RenderScore
    DIM s$
    RenderText 3, 0, "1UP", TEXT_WHITE
    RenderText 9, 0, "HIGH SCORE", TEXT_WHITE
    s$ = LTRIM$(STR$(game.score%)) ' Trimming the string because STR$ pads positive values with a leading space (to align with negative values that start with the negative character)
    RenderText 7 - LEN(s$), 1, s$, TEXT_YELLOW
    s$ = LTRIM$(STR$(game.hiscore%))
    RenderText 17 - LEN(s$), 1, s$, TEXT_YELLOW
END SUB

SUB RenderStartingGame
    RenderScore
    RenderText 9, 20, "PLAYER ONE", TEXT_WHITE
END SUB

SUB RenderGameOver
    RenderScore
    RenderText 9, 20, "PLAYER ONE", TEXT_WHITE
    RenderText 9, 22, "GAME  OVER", TEXT_WHITE
END SUB

SUB RenderTitle
    RenderScore
    RenderText 12, 6, "PLAY", TEXT_YELLOW
    RenderText 8, 9, "- SCRAMBLE -", TEXT_BLUE
    RenderText 3, 17, "HOW FAR CAN YOU INVADE", TEXT_RED
    RenderText 4, 20, "OUR SCRAMBLE SYSTEM ?", TEXT_RED
END SUB

SUB RenderStartKey
    STATIC counter&, pressed% ' Easier to use static variables as counters here to flip between the different messages displayed at the bottom of the screen
    SELECT CASE (counter& MOD (game.fps% * 6)) / game.fps%
        CASE 0 TO 1.6: RenderText 4, 31, "PRESS SPACE TO START", TEXT_WHITE
        CASE 2 TO 3.6: RenderText 3, 31, "ARROW KEYS TO FLY SHIP", TEXT_WHITE
        CASE 4 TO 5.6: RenderText 1, 31, "A TO FIRE - Z TO DROP BOMB", TEXT_WHITE
    END SELECT
    IF _KEYDOWN(32) THEN pressed% = TRUE ELSE IF pressed% = TRUE THEN pressed% = FALSE: SetGameState STATE_STARTING_GAME ' Start game after SPACE has been pressed and released
    counter& = counter& + 1
END SUB

SUB RenderHighscores
    DIM i%, s$, c%
    RenderScore
    RenderText 5, 4, "- SCORE RANKING -", TEXT_RED
    FOR i% = 0 TO 9
        c% = placeColour%(i%)
        IF i% = game.highlightScore% THEN c% = TEXT_WHITE
        RenderText 6, 7 + i% * 2, place$(i%), c%
        s$ = LTRIM$(STR$(hiscores%(i%))) + " PTS"
        RenderText 22 - LEN(s$), 7 + i% * 2, s$, c%
    NEXT i%
END SUB

' RenderScoreTable
' - Displays the attract loop's score information screen
SUB RenderScoreTable
    DIM i%, j%, c%
    RenderScore
    SetPalette 0
    RenderText 7, 7, "- SCORE TABLE -", TEXT_YELLOW
    RenderImage SPRITE_ROCKET, 0, 8 * 8, 2 + 9 * 8
    RenderImage SPRITE_ROCKET, 2, 8 * 8, 2 + 12 * 8
    RenderImage SPRITE_UFO, 0, 8 * 8, 2 + 15 * 8
    RenderImage SPRITE_FUEL, 0, 8 * 8, 2 + 18 * 8
    RenderImage SPRITE_BASE, 0, 8 * 8, 2 + 21 * 8
    RenderImage SPRITE_MYSTERY, 0, 8 * 8, 2 + 24 * 8
    c% = INT(game.frameCounter& / (game.fps% / 16)) - 1 ' We use c% based on the frameCounter to allow the text to appear one character at a time
    FOR i% = 0 TO 5
        FOR j% = 1 TO LEN(scoreTable$(i%))
            IF c% > 0 THEN RenderText 9 + j%, 10 + i% * 3, MID$(scoreTable$(i%), j%, 1), TEXT_WHITE
            c% = c% - 1
        NEXT j%
    NEXT i%
END SUB

SUB RenderReachedBase
    RenderScore
    IF game.baseDestroyed% THEN
        RenderText 7, 12, "CONGRATULATIONS", TEXT_RED
        RenderText 2, 14, "YOU COMPLETED YOUR DUTIES", TEXT_YELLOW
        RenderText 2, 16, "GOOD LUCK NEXT TIME AGAIN", TEXT_BLUE
    ELSE
        RenderText 4, 12, "DISASTER - YOU FAILED", TEXT_RED
        RenderText 5, 14, "TO DESTROY THE BASE", TEXT_YELLOW
        RenderText 10, 16, "TRY AGAIN", TEXT_BLUE
    END IF
END SUB

'===== Simple asset loading functions =================================================================================================================================================================

SUB AssetError (fname$)
    SCREEN 0
    PRINT "Unable to load "; fname$
    PRINT "Please make sure EXE is in same folder as scramble.bas"
    PRINT "(Set Run/Output EXE to Source Folder option in the IDE before compiling)"
    END
END SUB

FUNCTION LoadImage& (fname$)
    DIM asset&, f$
    f$ = "./assets/" + fname$ + ".png"
    asset& = _LOADIMAGE(f$, 256)
    IF asset& = -1 THEN AssetError (f$)
    LoadImage& = asset&
END FUNCTION

FUNCTION SndOpen& (fname$)
    DIM asset&, f$
    f$ = "./assets/" + fname$
    asset& = _SNDOPEN(f$)
    IF asset& = -1 THEN AssetError (f$)
    SndOpen& = asset&
END FUNCTION

SUB SetRect (r AS RECT, x%, y%, w%, h%)
    r.x% = x%
    r.y% = y%
    r.w% = w%
    r.h% = h%
    r.cx% = r.x% + r.w% / 2 ' Auto-populate cx% and cy% with the central positions of the rectangle
    r.cy% = r.y% + r.h% / 2
END SUB

'===== Terrain code ===================================================================================================================================================================================

' DrawPreStageTerrain
' - When you start any stage from a new life, you start on low, flat terrain that scrolls into the actual level data
SUB DrawPreStageTerrain
    DIM dataOffset%, column%
    ResetLandscape
    dataOffset% = stageDataOffset%(game.stage%) ' Set data pointer to start at beginning of current stage's data
    FOR column% = 0 TO NUM_COLUMNS - 1
        AddColumn column%, 0, 0, 20, 11, FillerType% ' Adds terrain that has no top and terrain at a set height at the bottom
        game.columnIndex% = game.columnIndex% XOR 1 ' Toggle the value used to alternate the FillerType tile for the terrain
    NEXT column%
END SUB

' Next column
' - Reads in thenext six bytes of terrain data which is all that's needed for terrain and object updates on that column
SUB NextColumn
    DIM i%, o%, d%
    IF game.dataIndex% < LEN(mapData$) THEN ' If we haven't reached the end of the BIN data...
        IF ASC(mapData$, game.dataIndex%) = 255 THEN ' If we've hit a 0xFF marker then this is the end of a stage so...
            IF game.stage% < 5 THEN ' If we're not already on the last level...
                game.stage% = game.stage% + 1 ' Progress the stage marker to the next level
                game.dataIndex% = game.dataIndex% + 1 ' and skip the 0xFF marker byte
            END IF
        END IF
    END IF
    i% = game.dataIndex%
    DO UNTIL i% < LEN(mapData$) ' This section loops the final stage without changing the actual dataIndex% value. This enables two seamless passes at the final level.
        i% = i% - (LEN(mapData$) - stageDataOffset%(game.stage%))
    LOOP
    ' Each six bytes of data in the BIN data contain the following information for a column -
    ' - Row number that the top of the terrain comes down to
    ' - Terrain tile to use for the top terrain (or zero if there is no terrain at the top of the screen)
    ' - Row number that the bottom of the terrain starts at
    ' - Terrain tile to use for the bottom terrain
    ' - Object type to spawn in this column (or zero for spawning no object)
    ' - Height at which to spawn the object
    AddColumn NUM_COLUMNS, ASC(mapData$, i%), INT(ASC(mapData$, i% + 1) / 2), ASC(mapData$, i% + 2), INT(ASC(mapData$, i% + 3) / 2), FillerType% ' Add a new column at the right of the screen
    o% = ASC(mapData$, i% + 4)
    d% = TRUE
    IF o% = 8 THEN
        IF ASC(mapData$, i% - 2) = 8 THEN d% = FALSE ' There's some weirdness in the data that has adjacent columns spawning certain objects so we can ignore those
    END IF
    IF d% THEN SpawnObjectFromData o%, ASC(mapData$, i% + 5)
    SpawnNonDataObjects ' UFOs and meteors are spawned from timers or regular intervals rather than from the BIN data
    game.dataIndex% = game.dataIndex% + 6
END SUB

' UpdateLandscape
' - This is called for every 8 pixels of scrolling (as terrain is 8-pixel tile based)
SUB UpdateLandscape
    ScrollLandscapeTiles ' Scroll existing landscape to the left
    NextColumn ' Add the next column using the BIN column data
    game.columnIndex% = game.columnIndex% XOR 1 ' Toggle the value used to alternate the terrain's filler block
    game.progressPalette% = game.progressPalette% + 1
    IF game.progressPalette% = 64 THEN NextPalette ' We need to update the palette for terrain, aliens, etc every 64 tiles
END SUB

SUB RenderLandscape (offset%)
    ' To save on drawing, calculating, etc, when a new column of terrain appears, I render it (in AddColumn) to a sprite so we have multiple sprites, each 8 pixels wide, which depict the terrain
    ' Each column sprite starts at 0, 8, 16, 24, etc
    ' For intervals between eight bytes we need to display them slightly offset (by bitOffset% bytes)
    DIM bitOffset%
    DIM i%
    bitOffset% = offset% AND 7
    FOR i% = 0 TO NUM_COLUMNS + 1
        _PUTIMAGE (i% * TILE_WIDTH - bitOffset%, 40), column(i%).texture&, ,
    NEXT i%
END SUB

SUB AddColumn (column%, topTileY%, topTile%, bottomTileY%, bottomTile%, fillerTile%)
    ' Each new terrain column is rendered to a sprite as mentioned in the previous function. This saves on processing as we're only doing this preparation once for each column
    DIM i%, handle&, o%
    i% = 0
    handle& = column(column%).texture& ' Get the handle for the sprite at whichever column we're updating - usually the rightmost except when updating the whole screen when the player starts a new life
    _DEST handle& ' Set this sprite as the one that we'll be rendering to
    CLS ' Clear the sprite
    column(column%).top% = topTileY%
    column(column%).bottom% = bottomTileY%
    IF topTile% > 0 THEN ' If the top tile is set to zero then there is no terrain at the top of the screen
        DO UNTIL i% = topTileY% ' Otherwise we will loop to fill the column with fillerTile to the designated height
            _PUTIMAGE (0, i% * TILE_HEIGHT), spriteSheet&, handle&, (tileU%(fillerTile%), tileV%(fillerTile%))-(tileU%(fillerTile%) + 7, tileV%(fillerTile%) + 7)
            i% = i% + 1
        LOOP
        IF topTile% > 63 THEN topTile% = topTile% - 44
        _PUTIMAGE (0, i% * TILE_HEIGHT), spriteSheet&, handle&, (tileU%(topTile%), tileV%(topTile%))-(tileU%(topTile%) + 7, tileV%(topTile%) + 7) ' And add the cap for the top piece of terrain
        i% = i% + 1
    END IF
    i% = bottomTileY% ' We now move to the top of the terrain at the bottom of the screen
    IF bottomTile% >= 33 THEN
        ' Special case here where we're dealing with the "KONAMI" text on the final level
        o% = spriteData(SPRITE_TEXT).offset% + bottomTile% - 33
        _PUTIMAGE (0, i% * TILE_HEIGHT), spriteSheet&, handle&, (spriteUV(o%).x%, spriteUV(o%).y%)-(spriteUV(o%).x% + spriteData(SPRITE_TEXT).size.x% - 1, spriteUV(o%).y% + spriteData(SPRITE_TEXT).size.y% - 1)
    ELSE
        ' Draw the cap for the terrain at the bottom of the screen
        _PUTIMAGE (0, i% * TILE_HEIGHT), spriteSheet&, handle&, (tileU%(bottomTile%), tileV%(bottomTile%))-(tileU%(bottomTile%) + 7, tileV%(bottomTile%) + 7)
    END IF
    i% = i% + 1
    DO UNTIL i% = NUM_ROWS ' And then loop through, filling the rest of the bottom of the terrain with the filler tile
        _PUTIMAGE (0, i% * TILE_HEIGHT), spriteSheet&, handle&, (tileU%(fillerTile%), tileV%(fillerTile%))-(tileU%(fillerTile%) + 7, tileV%(fillerTile%) + 7)
        i% = i% + 1
    LOOP
    _DEST virtualScreen& ' And remember to set the rendering target back to the virtual screen - we haven't rendered anything to that in this function, ust updated the terrain sprite strips themselves
END SUB

SUB ResetLandscape
    game.columnIndex = 0
END SUB

SUB ScrollLandscapeTiles
    ' Every column entry contains the handle to the terrain sprite for that column as well as data for the height of the top and bottom pieces of terrain for that column
    ' So every eight pixels we simply cascade the data along
    DIM i%, columnCache AS COLUMN
    columnCache = column(0)
    FOR i% = 0 TO NUM_COLUMNS - 1
        column(i%) = column(i% + 1)
    NEXT i%
    column(NUM_COLUMNS) = columnCache
END SUB

FUNCTION FillerType%
    ' The filler tile alternates on later levels (where it gives a brick-type effect)
    IF game.stage% < 3 THEN
        FillerType% = 14
    ELSE
        IF game.columnIndex MOD 2 = 0 THEN
            FillerType% = 16
        ELSE
            FillerType% = 19
        END IF
    END IF
END FUNCTION

'===== Player code ====================================================================================================================================================================================

SUB UpdatePlayer
    SELECT CASE player.state%
        CASE PLAYER_FLYING ' Normal state for the player when playing the game
            player.sprite.frame% = INT(game.frameCounter& / 8) MOD 3 ' Player sprite changes animation frame every 8 game frames - this animation frame index is locked to values between 0 and 2
            IF player.fuel% > 0 THEN
                player.fuelCounter% = player.fuelCounter% - 1 ' If we hve fuel then we should reduce the related frame counter
                IF player.fuelCounter% = 0 THEN
                    player.fuelCounter% = player.fuelSpeed%
                    player.fuel% = player.fuel% - 1 ' and reduce the actual fuel amount when the counter reaches zero
                    IF player.fuel% = 20 THEN
                        PlaySfxLooping SFX_FUEL_WARNING
                    END IF
                END IF
            END IF
            IF game.state% = STATE_PLAY THEN ' If we're playing the game (as opposed to in a demo sequence for example)...
                IF player.fuel% > 0 THEN ' Only allow player control when we have fuel
                    player.sprite.position.x% = player.sprite.position.x% + _KEYDOWN(KEYDOWN_LEFT) - _KEYDOWN(KEYDOWN_RIGHT)
                    player.sprite.position.y% = player.sprite.position.y% + _KEYDOWN(KEYDOWN_UP) - _KEYDOWN(KEYDOWN_DOWN)
                ELSE
                    player.sprite.position.y% = player.sprite.position.y% + 1 ' Simply drop when we're out of fuel
                END IF
                IF player.sprite.position.x% < 8 THEN player.sprite.position.x% = 8 ELSE IF player.sprite.position.x% > SCREEN_WIDTH / 2 - 24 THEN player.sprite.position.x% = SCREEN_WIDTH / 2 - 24 ' Limit player to left half of screen
                IF player.sprite.position.y% < 0 THEN player.sprite.position.y% = 0 ELSE IF player.sprite.position.y% > GAME_HEIGHT - 16 THEN player.sprite.position.y% = GAME_HEIGHT - 16
                IF player.firePause% = 0 THEN
                    IF _KEYDOWN(KEYDOWN_FIRE) THEN
                        IF NOT player.firePressed% THEN
                            player.firePressed% = TRUE ' Use this value to prevent firing when fire button is simply held down
                            player.firePause = 4 ' We have a slight delay between allowing fire button to be spammed - 4 frames of animation is hardly perceptible but does make a difference
                            PlaySfx SFX_LASER
                            CreateAmmo AMMO_BULLET
                        END IF
                    ELSE
                        player.firePressed% = FALSE
                    END IF
                ELSE
                    player.firePause% = player.firePause% - 1
                END IF
                IF player.bombPause% = 0 THEN ' Bombing works the same way as firing except that the player is limited to two active bombs at any given time
                    IF _KEYDOWN(KEYDOWN_BOMB) THEN
                        IF NOT player.bombPressed% THEN
                            player.bombPressed% = TRUE
                            IF BombCount% < 2 THEN
                                player.bombPause = 4
                                PlaySfx SFX_BOMB
                                CreateAmmo AMMO_BOMB
                            END IF
                        END IF
                    ELSE
                        player.bombPressed% = FALSE
                    END IF
                ELSE
                    player.bombPause% = player.bombPause% - 1
                END IF
            END IF

        CASE PLAYER_SPAWNING ' Basically the initialisation state for a new player's life having spawned
            player.state% = PLAYER_FLYING
            game.lives% = game.lives% - 1
            PlaySfxLooping SFX_ENGINE
    END SELECT
END SUB

SUB RenderPlayer
    IF player.state% = PLAYER_FLYING THEN RenderSprite player.sprite, 40 ' We only render the player's sprite when it is flying (as opposed to exploding, etc)
END SUB

' DestroyPlayer
' - the player is destroyed so set the new player state and spawn an explosion
SUB DestroyPlayer
    player.state% = PLAYER_EXPLODING
    SpawnSprite SPRITE_PLAYER_EXPLOSION, player.sprite.position: PlaySfx SFX_EXPLOSION
END SUB

'===== Game enemy object handling =====================================================================================================================================================================

SUB UpdateObjects
    DIM i%
    FOR i% = objectCount% - 1 TO 0 STEP -1 ' We're doing this backwards so that we can delete objects during the update (which collapse the list to fill the newly created space)
        object(i%).sprite.counter% = object(i%).sprite.counter% + 1
        SELECT CASE object(i%).sprite.spriteId%
            CASE TYPE_MISSILE: UpdateMissile (i%)
            CASE TYPE_UFO: UpdateUfo (i%)
            CASE TYPE_BASE: UpdateBase (i%)
            CASE TYPE_METEOR: UpdateMeteor (i%)
        END SELECT
        IF object(i%).sprite.position.x% < -15 OR object(i%).sprite.position.y% < -15 THEN RemoveObject (i%) ' Remove an object if it's gone of the left or top of the screen
    NEXT i%
END SUB

SUB UpdateMissile (i%)
    IF object(i%).inFlight THEN
        object(i%).sprite.position.y% = object(i%).sprite.position.y% - 1 ' A missile in flight simple travels upwards
        object(i%).sprite.frame% = 1 + (INT(object(i%).sprite.counter% / 8) AND 1) ' The animating frame of a missile toggles between 1 and 2 every 8 game frames
    ELSE
        IF NOT (game.stage% = 1 OR game.stage% = 2) THEN ' Missiles don't take off in the second or third game stage
            IF game.state% = STATE_DEMO THEN
                IF object(i%).sprite.position.x% = 40 THEN object(i%).inFlight% = TRUE ' Force the missile to always take off at the same time during the demo stage
            ELSE
                IF object(i%).sprite.position.x% = NUM_COLUMNS * 4 THEN ' When we're exactly half way across the screen we have a one in four chance of setting a missile into a flight state
                    IF RND < 0.25 THEN object(i%).inFlight% = TRUE
                ELSEIF object(i%).sprite.position.x% < NUM_COLUMNS * 4 THEN ' At any point past half way, we have a small chance of going into a flight state as the game scrolls
                    IF RND < 0.01 THEN object(i%).inFlight% = TRUE
                END IF
            END IF
        END IF
    END IF
END SUB

SUB UpdateBase (i%)
    object(i%).sprite.frame% = INT(object(i%).sprite.counter% / 8) MOD 3 ' The base has three frames of animation (and changes every 8 game frames)
END SUB

SUB UpdateMeteor (i%)
    object(i%).sprite.position.x% = object(i%).sprite.position.x% - 3 ' Meteors fly to the left
    object(i%).sprite.frame% = INT(object(i%).sprite.counter% / 8) AND 3 ' And have three frames of animation that update every 8 game frames
END SUB

SUB UpdateUfo (i%)
    object(i%).sprite.position.y% = GAME_HEIGHT / 2 - 8 + 32 * SIN(_D2R(object(i%).sprite.counter% * 6)) ' UFOs have sinusoidal flight patterns
END SUB

SUB RenderObjects
    DIM i%
    FOR i% = 0 TO objectCount% - 1
        RenderSprite object(i%).sprite, 40 ' Renders at an offset of 40 pixels - this is the space taken by the HUD area at the top of the screen
    NEXT i%
END SUB

SUB RemoveObject (i%) ' When we remoe an object from the array, we move the last object in the remaining array into this space so that we have consecutive data in the array
    object(i%) = object(objectCount% - 1)
    objectCount% = objectCount% - 1
END SUB

SUB DestroyObject (i%)
    DIM d%
    SELECT CASE object(i%).sprite.spriteId%
        ' Perform requisite actions and updates depending on the object type that has been destroyed
        CASE TYPE_METEOR: EXIT SUB
        CASE TYPE_MISSILE: SpawnSprite SPRITE_OBJECT_EXPLOSION, object(i%).sprite.position: d% = 50 - 30 * object(i%).inFlight%: PlaySfx SFX_ROCKET_EXPLOSION
        CASE TYPE_FUEL: SpawnSprite SPRITE_OBJECT_EXPLOSION, object(i%).sprite.position: d% = 150: player.fuel% = player.fuel% + 15: PlaySfx SFX_EXPLOSION: IF player.fuel% > 20 THEN StopSfx SFX_FUEL_WARNING: IF player.fuel% > MAX_FUEL THEN player.fuel% = MAX_FUEL
        CASE TYPE_MYSTERY: d% = INT(RND * 3): SpawnSprite SPRITE_MYSTERY_SCORE, object(i%).sprite.position: spawnedSprite(spawnedSpriteCount% - 1).frame% = d%: d% = (d% + 1) * 100: PlaySfx SFX_EXPLOSION
        CASE TYPE_BASE: SpawnSprite SPRITE_OBJECT_EXPLOSION, object(i%).sprite.position: d% = 800: PlaySfx SFX_EXPLOSION: game.baseDestroyed% = TRUE
        CASE TYPE_UFO: SpawnSprite SPRITE_UFO_EXPLOSION, object(i%).sprite.position: d% = 100: PlaySfx SFX_ROCKET_EXPLOSION
    END SELECT
    IF game.state% = STATE_PLAY THEN IncreaseScore (d%) ' We only score if we're actually playing a game (so not in demo state for example)
    RemoveObject i%
END SUB

'===== Background stars ===============================================================================================================================================================================

SUB UpdateStars
    stars.counter% = stars.counter% + 1
    IF stars.counter% >= game.fps% THEN ' Change the frame being displayed every one second
        stars.counter% = 0
        stars.frame% = stars.frame% + 1
        IF stars.frame% = 4 THEN stars.frame% = 1
    END IF
END SUB

SUB RenderStars
    ' We always display the first stars frame in addition to another that varies every second
    _PUTIMAGE , stars.sprite0&
    SELECT CASE stars.frame%
        CASE 1: _PUTIMAGE , stars.sprite2&: _PUTIMAGE , stars.sprite3&
        CASE 2: _PUTIMAGE , stars.sprite1&: _PUTIMAGE , stars.sprite3&
        CASE 3: _PUTIMAGE , stars.sprite1&: _PUTIMAGE , stars.sprite2&
    END SELECT
END SUB

'===== Player's ammo ==================================================================================================================================================================================

SUB RenderAmmo
    DIM i%
    FOR i% = 0 TO ammoCount% - 1
        RenderSprite ammo(i%), 40
    NEXT i%
END SUB

SUB UpdateAmmo
    DIM i%
    FOR i% = ammoCount% - 1 TO 0 STEP -1 ' Traversing the array backwards so we can remove finished ammo mid-loop (and fill the gaps in the array)
        SELECT CASE ammo(i%).spriteId%
            CASE AMMO_BULLET:
                ammo(i%).position.x% = ammo(i%).position.x% + 4
                IF ammo(i%).position.x% > SCREEN_WIDTH THEN
                    ammo(i%) = ammo(ammoCount% - 1) ' When the ammo leaves the screen, replce with last item in list and reduce ammo counter
                    ammoCount% = ammoCount% - 1
                END IF
            CASE AMMO_BOMB:
                SELECT CASE ammo(i%).counter% ' Set the appropriate bomb animation frame
                    CASE 0: ammo(i%).frame% = 0
                    CASE 4: ammo(i%).frame% = 1
                    CASE 8: ammo(i%).frame% = 0
                    CASE 16: ammo(i%).frame% = 2
                    CASE 28: ammo(i%).frame% = 3
                    CASE 40: ammo(i%).frame% = 4
                END SELECT
                SELECT CASE ammo(i%).counter% ' Mimic the trajectory of bombs in the original arcade game
                    CASE 0 TO 15: ammo(i%).position.x% = ammo(i%).position.x% + 1
                    CASE 16 TO 27: ammo(i%).position.x% = ammo(i%).position.x% + 1: ammo(i%).position.y% = ammo(i%).position.y% + 1 - (ammo(i%).counter% AND 1)
                    CASE 28 TO 39: ammo(i%).position.x% = ammo(i%).position.x% + (ammo(i%).counter% AND 1): ammo(i%).position.y% = ammo(i%).position.y% + 1
                    CASE ELSE: ammo(i%).position.y% = ammo(i%).position.y% + 1
                END SELECT
                ammo(i%).counter% = ammo(i%).counter% + 1
        END SELECT
    NEXT i%
END SUB

SUB DestroyAmmo (i%)
    IF ammo(i%).spriteId% = AMMO_BOMB THEN SpawnSprite SPRITE_BOMB_EXPLOSION, ammo(i%).position: PlaySfx SFX_SMALL_EXPLOSION: StopSfx SFX_BOMB
    ammo(i%) = ammo(ammoCount% - 1)
    ammoCount% = ammoCount% - 1
END SUB

SUB CreateAmmo (ammoType%)
    SELECT CASE ammoType%
        CASE AMMO_BULLET: SetSprite ammo(ammoCount%), ammoType%, player.sprite.position.x% + 28, player.sprite.position.y% + 4
        CASE AMMO_BOMB: SetSprite ammo(ammoCount%), ammoType%, player.sprite.position.x% + 10, player.sprite.position.y% + 6
    END SELECT
    ammoCount% = ammoCount% + 1
END SUB

' BombCount%
' - Counts the number of active bombs
FUNCTION BombCount%
    DIM c%, i%
    FOR i% = 0 TO ammoCount% - 1
        c% = c% - (ammo(i%).spriteId% = AMMO_BOMB) ' Uses boolean logic which yields -1 for a match and 0 for a non-match
    NEXT i%
    BombCount% = c%
END FUNCTION

'===== Sound manager ==================================================================================================================================================================================

SUB LoadSfx (sfx%, sfx$)
    sfx&(sfx%) = _SNDOPEN("assets/" + sfx$ + ".ogg")
    IF sfx&(sfx%) = 0 THEN AssetError sfx$
END SUB

SUB LoadAllSFX
    LoadSfx SFX_LASER, "laser"
    LoadSfx SFX_FUEL_WARNING, "fuel-warning"
    LoadSfx SFX_SMALL_EXPLOSION, "small-explosion"
    LoadSfx SFX_ENGINE, "engine"
    LoadSfx SFX_ROCKET_EXPLOSION, "rocket-explosion"
    LoadSfx SFX_BOMB, "bomb"
    LoadSfx SFX_START_GAME, "start-game"
    LoadSfx SFX_EXPLOSION, "explosion"
END SUB

SUB PlaySfx (sfx%)
    IF NOT game.state% = STATE_DEMO THEN _SNDPLAY sfx&(sfx%)
END SUB

SUB PlaySfxLooping (sfx%)
    IF NOT game.state% = STATE_DEMO THEN _SNDLOOP sfx&(sfx%)
END SUB

SUB StopSfx (sfx%)
    _SNDSTOP sfx&(sfx%)
END SUB

FUNCTION IsPlayingSfx% (sfx%)
    IsPlayingSfx% = _SNDPLAYING(sfx&(sfx%))
END FUNCTION

'===== Collision detection ============================================================================================================================================================================

SUB CalculateCollisions (xOffset%)
    DIM bitOffset%
    bitOffset% = xOffset% AND 7
    IF player.state% = PLAYER_FLYING THEN
        ' Check player against terrain and against other game objects
        ' Note that terrain collision takes the seven pixel offset from the current position. This is because the terrain is grid based on eight pixel boundaries so we need the exact pixel offset for collisions
        IF CheckMapCollision%(bitOffset%, player.sprite.position.x% + 8, player.sprite.position.y%, PLAYER_WIDTH - 8, PLAYER_HEIGHT) THEN DestroyPlayer ELSE IF CheckObjectCollision% THEN DestroyPlayer
    END IF
    CheckAmmoCollisions bitOffset% ' Again, this offset is required for checking collisions against terrain
END SUB

FUNCTION CheckMapCollision% (xOffset%, x%, y%, w%, h%)
    DIM cLeft%, cRight%, cTop%, cBottom%, i%
    ' Calculate the 8x8 tile positions for the left, top, right and bottom parts of the player's ship (and we take the inter-tile xOffset% into consideration)
    cLeft% = INT((x% + xOffset%) / TILE_WIDTH)
    cRight% = INT((x% + w% - 1 + xOffset%) / TILE_WIDTH)
    cTop% = INT(y% / TILE_HEIGHT)
    cBottom% = INT((y% + h% - 1) / TILE_HEIGHT)
    FOR i% = cLeft% TO cRight%
        IF cTop% < column(i%).top% OR cBottom% > column(i%).bottom% THEN CheckMapCollision% = TRUE: EXIT FUNCTION ' Check if the player has collided with the top or bottom terrain
    NEXT i%
    CheckMapCollision% = FALSE
END FUNCTION

FUNCTION CheckObjectCollision%
    ' Check object/player collisions using the collision boxes
    DIM i%
    FOR i% = 0 TO objectCount% - 1
        IF SpriteCollision%(player.sprite, object(i%).sprite) THEN DestroyObject i%: CheckObjectCollision% = TRUE: EXIT FUNCTION
    NEXT i%
    CheckObjectCollision% = FALSE
END FUNCTION

SUB CheckAmmoCollisions (xOffset%)
    DIM c%, i%, o%, p%
    ' Check collisions between ammo and enemy objects using their hitboxes
    FOR o% = objectCount% - 1 TO 0 STEP -1
        FOR i% = ammoCount% - 1 TO 0 STEP -1
            IF SpriteCollision%(ammo(i%), object(o%).sprite) THEN DestroyObject o%: DestroyAmmo (i%): EXIT FOR
        NEXT i%
    NEXT o%
    ' Check collisions between ammo and terrain
    FOR i% = ammoCount% - 1 TO 0 STEP -1
        c% = INT(((ammo(i%).position.x% + spriteData(ammo(i%).spriteId%).hitbox.cx%) + xOffset%) / TILE_WIDTH)
        p% = ammo(i%).position.y% + spriteData(ammo(i%).spriteId%).hitbox.cy%
        IF p% - 2 < column(c%).top% * TILE_HEIGHT OR p% + 2 > column(c%).bottom% * TILE_HEIGHT THEN DestroyAmmo (i%)
    NEXT i%
END SUB

FUNCTION SpriteCollision% (s1 AS SPRITE, s2 AS SPRITE)
    ' Hit box collision testing
    DIM dx%, dy%
    dx% = ABS((s1.position.x% + spriteData(s1.spriteId).hitbox.cx%) - (s2.position.x% + spriteData(s2.spriteId).hitbox.cx%))
    dy% = ABS((s1.position.y% + spriteData(s1.spriteId).hitbox.cy%) - (s2.position.y% + spriteData(s2.spriteId).hitbox.cy%))
    SpriteCollision% = dx% < (spriteData(s1.spriteId).hitbox.w% + spriteData(s2.spriteId).hitbox.w%) / 2 AND dy% < (spriteData(s1.spriteId).hitbox.h% + spriteData(s2.spriteId).hitbox.h%) / 2
END FUNCTION

'===== Spawned sprite handling ========================================================================================================================================================================

SUB SpawnSprite (spriteId%, p AS POINT)
    SetSprite spawnedSprite(spawnedSpriteCount%), spriteId%, p.x%, p.y%
    spawnedSpriteCount% = spawnedSpriteCount% + 1
END SUB

SUB UpdateSpawnedSprites
    DIM i%, id%
    FOR i% = spawnedSpriteCount% - 1 TO 0 STEP -1
        spawnedSprite(i%).counter% = spawnedSprite(i%).counter% + 1
        id% = spawnedSprite(i%).spriteId%
        SELECT CASE id%
            CASE SPRITE_PLAYER_EXPLOSION: IF spawnedSprite(i%).counter% = 112 THEN RemoveSpawnedSprite i% ELSE spawnedSprite(i%).frame% = playerExplosionFrameOrder%(INT(spawnedSprite(i%).counter% / 16)): IF (spawnedSprite(i%).counter% AND 3) = 0 THEN NextPalette
            CASE SPRITE_MYSTERY_SCORE: IF spawnedSprite(i%).counter% = 48 THEN RemoveSpawnedSprite i%
            CASE ELSE: IF spawnedSprite(i%).counter% = 64 THEN RemoveSpawnedSprite i% ELSE spawnedSprite(i%).frame% = INT(spawnedSprite(i%).counter% / 8) AND 3
        END SELECT
    NEXT i%
END SUB

SUB RemoveSpawnedSprite (i%)
    spawnedSprite(i%) = spawnedSprite(spawnedSpriteCount% - 1)
    spawnedSpriteCount% = spawnedSpriteCount% - 1
END SUB

'===== Rendering utility code =========================================================================================================================================================================

' RenderSprite
' - yOffset% simply allows the transposing of sprites (generally for game play to be moved below the top HUD area with scores, etc)
SUB RenderSprite (s AS SPRITE, yOffset%)
    DIM o%
    o% = spriteData(s.spriteId%).offset% + s.frame%
    _PUTIMAGE (s.position.x%, s.position.y% + yOffset%), spriteSheet&, , (spriteUV(o%).x%, spriteUV(o%).y%)-(spriteUV(o%).x% + spriteData(s.spriteId%).size.x% - 1, spriteUV(o%).y% + spriteData(s.spriteId%).size.y% - 1)
END SUB

SUB RenderImage (id%, f%, x%, y%)
    DIM o%
    o% = spriteData(id%).offset% + f%
    _PUTIMAGE (x%, y%), spriteSheet&, , (spriteUV(o%).x%, spriteUV(o%).y%)-(spriteUV(o%).x% + spriteData(id%).size.x% - 1, spriteUV(o%).y% + spriteData(id%).size.y% - 1)
END SUB

SUB RenderText (x%, y%, t$, c%)
    DIM i%, c$
    FOR i% = 0 TO LEN(t$) - 1
        c$ = MID$(t$, i% + 1, 1)
        IF c$ <> " " THEN RenderImage SPRITE_TEXT, c% * LEN(text$) + INSTR(text$, c$) - 1, (x% + i%) * 8, y% * 8
    NEXT i%
END SUB

SUB SetPalette (p%)
    DIM i%
    FOR i% = 0 TO 3
        _PALETTECOLOR gPal%(i%), pal&(paletteOrder%(p%), i%), 0
    NEXT i%
    game.currentPalette% = p%
    game.progressPalette% = 0
END SUB

SUB NextPalette
    SetPalette (game.currentPalette% + 1) MOD 7 ' Moves to the next palette index (0 to 6)
END SUB

'===== Game utility functions =========================================================================================================================================================================

' IncreaseScore
' - Any score increases are sent through this function so we can monitor extra lives and high scores
SUB IncreaseScore (d%)
    game.score% = game.score% + d%
    IF game.score% >= 10000 AND game.score% - d% < 10000 THEN game.lives% = game.lives% + 1
    IF game.score% > game.hiscore% THEN game.hiscore% = game.score%
END SUB

SUB PrepareForLevel
    objectCount% = 0 ' No objects at stage initialisation time
    spawnedSpriteCount% = 0 ' No spawned sprites at this time
    ammoCount% = 0 ' No ammo is active
    player.state% = PLAYER_SPAWNING ' Set the player to spawn
    player.fuelCounter% = player.fuelSpeed% ' Reset the fuel counter for the current fuel speed counter
    player.fuel% = MAX_FUEL ' Fill the tank
    SetPalette 0 ' Default palette
    game.scrollOffset% = 0 ' Starting at the beginning of the stage
    game.dataIndex = stageDataOffset%(game.stage%) ' Set the index to point into the BIN data at the correct point for the beginning of the stage
    game.baseDestroyed% = FALSE ' The final base hasn't been destryed at this point
    DrawPreStageTerrain ' Update the full screen with terrain
    NextColumn ' And the column that's about to scroll on
    UpdateScroll
    SetSprite player.sprite, SPRITE_PLAYER, 8, 40
    StopSfx SFX_FUEL_WARNING
    StopSfx SFX_ENGINE
END SUB

' LifeLost%
' - Helper function that returns true when the player is exploding and the explosion frames have completed
FUNCTION LifeLost%
    LifeLost% = (player.state% = PLAYER_EXPLODING) AND spawnedSpriteCount% = 0
END FUNCTION

SUB BaseDefeated
    ' If the base has been blown up in the final stage then go back to the first stage after incrementing the flag count and adjusting the fuel speed to drain slightly quicker
    game.stage% = 0
    PrepareForLevel
    player.fuelSpeed% = player.fuelSpeed% - 1
    game.flagCount% = game.flagCount% + 1
END SUB

' SetGameState
' - When we set a new game state we do it through this function so that any necessary initialisation for that state can take place
SUB SetGameState (s%)
    game.state% = s%
    game.frameCounter& = 0
    IF s% = STATE_TITLE OR s% = STATE_HIGHSCORES THEN game.stage% = 0: player.fuelSpeed% = INITIAL_FUEL_SPEED
    IF s% = STATE_STARTING_GAME THEN game.lives% = 3: game.score% = 0: game.hiscore% = hiscores%(0): game.flagCount% = 1: PrepareForLevel: PlaySfx SFX_START_GAME
    IF s% = STATE_GAME_OVER THEN StopSfx SFX_FUEL_WARNING: StopSfx SFX_ENGINE: CheckScore
    IF s% = STATE_REACHED_BASE THEN StopSfx SFX_FUEL_WARNING: StopSfx SFX_ENGINE
END SUB

' SetSprite
' - Set sprite data for any sprite being added to the display
SUB SetSprite (s AS SPRITE, id%, x%, y%)
    s.spriteId% = id%
    s.position.x% = x%
    s.position.y% = y%
    s.counter% = 0
    s.frame% = 0
END SUB

SUB InitialiseStageDataOffset
    DIM dataOffset%, stage%
    dataOffset% = 1
    stageDataOffset%(0) = dataOffset% ' The first stage starts at the beginning of the data
    stage% = 1
    DO UNTIL stage% = NUM_STAGES
        dataOffset% = dataOffset% + 6 ' Each column of tile data consists of 6 bytes of information
        IF ASC(mapData$, dataOffset%) = 255 THEN ' The end of a stage is depicted by a lone 0xFF byte marker
            dataOffset% = dataOffset% + 1 ' Skip the marker if we've found it
            stageDataOffset%(stage%) = dataOffset% ' And update the array as we've found the beginning of the next stage's data
            stage% = stage% + 1
        END IF
    LOOP
END SUB

' SpawnObjectFromData
' - For spawning objects as per the game's BIN data
SUB SpawnObjectFromData (positionY%, objectType%)
    IF positionY% = 0 OR objectType% > 15 THEN EXIT SUB
    SpawnObject positionY%, LOG(objectType%) / LOG(2)
END SUB

' SpawnObject
'- For spawning UFOs and meteors that aren't defined in the game's BIN data
SUB SpawnObject (positionY%, objectType%)
    SetSprite object(objectCount%).sprite, objectType%, NUM_COLUMNS * TILE_WIDTH, positionY% * TILE_HEIGHT
    object(objectCount%).inFlight% = FALSE
    objectCount% = objectCount% + 1
END SUB

' SpawnNonDataObjects
' - Spawn UFOs and meteors when necessary
SUB SpawnNonDataObjects
    IF game.stage% = 1 THEN
        IF ((game.dataIndex% - stageDataOffset%(game.stage%)) / 6) MOD 10 = 0 AND game.dataIndex% < stageDataOffset%(2) - NUM_COLUMNS * 6 THEN SpawnObject 0, TYPE_UFO
    ELSEIF game.stage% = 2 THEN
        IF ((game.dataIndex% - stageDataOffset%(game.stage%)) / 6) MOD 2 = 0 AND game.dataIndex% < stageDataOffset%(3) - NUM_COLUMNS * 6 THEN SpawnObject RND * (NUM_ROWS - 11) + 1, TYPE_METEOR
    END IF
END SUB

' CheckScore
' - See if the player has made the leaderboard (and set to highlight the score in the table if so)
SUB CheckScore
    DIM i%, j%
    game.highlightScore% = -1
    FOR i% = 0 TO 9
        IF game.score% > hiscores%(i%) THEN
            FOR j% = 9 TO i% + 1 STEP -1
                hiscores%(j%) = hiscores%(j% - 1)
            NEXT j%
            hiscores%(i%) = game.score%
            game.highlightScore% = i%
            WriteHiscores
            EXIT SUB
        END IF
    NEXT i%
END SUB

'======================================================================================================================================================================================================


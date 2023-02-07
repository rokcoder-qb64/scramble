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

CONST SCREEN_WIDTH = 224
CONST SCREEN_HEIGHT = 256
CONST NUM_STAGES = 6
CONST TILE_WIDTH = 8
CONST TILE_HEIGHT = 8
CONST NUM_COLUMNS = INT(SCREEN_WIDTH / TILE_WIDTH)
CONST NUM_ROWS = 25
CONST GAME_HEIGHT = NUM_ROWS * TILE_HEIGHT

CONST KEYDOWN_LEFT = 19200
CONST KEYDOWN_RIGHT = 19712
CONST KEYDOWN_UP = 18432
CONST KEYDOWN_DOWN = 20480
CONST KEYDOWN_FIRE = 97
CONST KEYDOWN_BOMB = 122

CONST PLAYER_FLYING = 0
CONST PLAYER_EXPLODING = 1
CONST PLAYER_SPAWNING = 2

CONST PLAYER_WIDTH = 32
CONST PLAYER_HEIGHT = 16

CONST MAX_FUEL = 112
CONST INITIAL_FUEL_SPEED = 20
CONST DELTA_FUEL_SPEED_PER_PASS = 2

CONST AMMO_BULLET = 18
CONST AMMO_BOMB = 8

CONST TYPE_MISSILE = 0
CONST TYPE_FUEL = 1
CONST TYPE_MYSTERY = 2
CONST TYPE_BASE = 3
CONST TYPE_METEOR = 4
CONST TYPE_UFO = 5

CONST SPRITE_ROCKET = 0
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

CONST SFX_LASER = 0
CONST SFX_FUEL_WARNING = 1
CONST SFX_SMALL_EXPLOSION = 2
CONST SFX_ENGINE = 3
CONST SFX_ROCKET_EXPLOSION = 4
CONST SFX_BOMB = 5
CONST SFX_START_GAME = 6
CONST SFX_EXPLOSION = 7

CONST text$ = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789?c.- "

CONST TEXT_WHITE = 0
CONST TEXT_RED = 1
CONST TEXT_BLUE = 2
CONST TEXT_YELLOW = 3
CONST TEXT_PURPLE = 4

CONST STATE_TITLE = 0
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
    x AS INTEGER
    y AS INTEGER
    w AS INTEGER
    h AS INTEGER
    cx AS INTEGER
    cy AS INTEGER
END TYPE

TYPE SPRITE
    spriteId AS INTEGER
    position AS POINT
    frame AS INTEGER
    counter AS INTEGER
END TYPE

TYPE SPRITEDATA
    offset AS INTEGER
    size AS POINT
    hitbox AS RECT
END TYPE

TYPE PLAYER
    sprite AS SPRITE
    state AS INTEGER
    fuel AS INTEGER
    fuelCounter AS INTEGER
    fuelSpeed AS INTEGER
    firePause AS INTEGER
    firePressed AS INTEGER
    bombPause AS INTEGER
    bombPressed AS INTEGER
END TYPE

TYPE OBJECT
    sprite AS SPRITE
    inFlight AS INTEGER
END TYPE

TYPE GAME
    frameCounter AS LONG
    fps AS INTEGER
    dataIndex AS INTEGER
    columnIndex AS INTEGER
    stage AS INTEGER
    currentPalette AS INTEGER
    progressPalette AS INTEGER
    score AS INTEGER
    hiscore AS INTEGER
    lives AS INTEGER
    scrollOffset AS INTEGER
    state AS INTEGER
    highlightScore AS INTEGER
    baseDestroyed AS INTEGER
    flagCount AS INTEGER
END TYPE

TYPE COLUMN
    texture AS LONG
    top AS INTEGER
    bottom AS INTEGER
END TYPE

TYPE SPAWNDATA
    x AS INTEGER
    y AS INTEGER
    count AS INTEGER
END TYPE

TYPE STARS
    sprite0 AS LONG
    sprite1 AS LONG
    sprite2 AS LONG
    sprite3 AS LONG
    frame AS INTEGER
    counter AS INTEGER
END TYPE

'======================================================================================================================================================================================================

DIM SHARED spriteSheet&
DIM SHARED virtualScreen&
DIM SHARED mapData$
DIM SHARED game AS GAME
DIM SHARED spriteData(64) AS SPRITEDATA
DIM SHARED stageDataOffset%(6)
DIM SHARED column(NUM_COLUMNS + 1) AS COLUMN
DIM SHARED ammo(32) AS SPRITE
DIM SHARED ammoCount%
DIM SHARED object(16) AS OBJECT
DIM SHARED objectCount%
DIM SHARED player AS PLAYER
DIM SHARED pal&(8, 4), gPal%(4)
DIM SHARED tileU%(27), tileV%(27)
DIM SHARED paletteOrder%(7)
DIM SHARED spawnedSprite(32) AS SPRITE
DIM SHARED spawnedSpriteCount%
DIM SHARED spriteUV(320) AS POINT
DIM SHARED sfx&(8)
DIM SHARED stars AS STARS
DIM SHARED playerExplosionFrameOrder%(7)
DIM SHARED place$(10)
DIM SHARED placeColour%(10)
DIM SHARED scoreTable$(6)
DIM SHARED hiscores%(10)

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
    m% = INT((_DESKTOPHEIGHT - 80) / SCREEN_HEIGHT)
    virtualScreen& = _NEWIMAGE(SCREEN_WIDTH, SCREEN_HEIGHT, 256)
    FOR i% = 0 TO NUM_COLUMNS
        column(i%).texture& = _NEWIMAGE(TILE_WIDTH, SCREEN_HEIGHT, 256)
        _CLEARCOLOR _RGB(0, 0, 0), column(i%).texture&
    NEXT i%
    SCREEN _NEWIMAGE(SCREEN_WIDTH * m%, SCREEN_HEIGHT * m%, 256)
    _DELAY 0.5
    _SCREENMOVE _MIDDLE
    '$RESIZE:STRETCH
    _ALLOWFULLSCREEN _SQUAREPIXELS , _SMOOTH
    _TITLE "Scramble"
    _DEST virtualScreen&
    game.fps% = 60
    RANDOMIZE TIMER
    game.frameCounter& = 0
    spriteSheet& = LoadImage&("sprite-sheet")
    _CLEARCOLOR _RGB(0, 0, 0), spriteSheet&
    stars.sprite0& = LoadImage&("stars-1")
    stars.sprite1& = LoadImage&("stars-2")
    stars.sprite2& = LoadImage&("stars-3")
    stars.sprite3& = LoadImage&("stars-4")
    _CLEARCOLOR _RGB(0, 0, 0), stars.sprite1&
    _CLEARCOLOR _RGB(0, 0, 0), stars.sprite2&
    _CLEARCOLOR _RGB(0, 0, 0), stars.sprite3&
    stars.frame% = 1
    LoadDataFromROM
    PrepareSprites
    ExtractPalettes
    ReadData
    InitialiseStageDataOffset
    LoadAllSFX
    ReadHiscores
    game.highlightScore% = -1
    game.hiscore% = hiscores%(0)
    SetGameState STATE_TITLE
END SUB

SUB PrepareSprites
    DIM i%, c%
    i% = 0
    SetSpriteataWithHitbox SPRITE_PLAYER, i%, 32, 16, 6, 2, 26, 12
    AddSpriteStrip i%, 1, 7, 4, 0, 18
    SetSpriteData SPRITE_PLAYER_EXPLOSION, i%, 32, 16
    AddSpriteStrip i%, 69, 7, 4, 0, 18
    SetSpriteataWithHitbox SPRITE_BOMB, i%, 16, 16, 6, 6, 4, 4
    AddSpriteStrip i%, 103, 7, 5, 0, 18
    SetSpriteData SPRITE_BOMB_EXPLOSION, i%, 16, 16
    AddSpriteStrip i%, 121, 7, 4, 0, 18
    SetSpriteData SPRITE_UFO_EXPLOSION, i%, 16, 16
    AddSpriteStrip i%, 139, 7, 4, 0, 18
    SetSpriteataWithHitbox SPRITE_METEOR, i%, 16, 16, 0, 3, 16, 10
    AddSpriteStrip i%, 157, 7, 4, 0, 18
    SetSpriteData SPRITE_LIVE, i%, 16, 8
    AddSpriteStrip i%, 1, 78, 1, 0, 0
    SetSpriteData SPRITE_LEVEL_FLAG, i%, 8, 8
    AddSpriteStrip i%, 19, 78, 1, 0, 0
    SetSpriteataWithHitbox SPRITE_UFO, i%, 16, 16, 2, 4, 12, 8
    AddSpriteStrip i%, 121, 79, 1, 0, 0
    SetSpriteataWithHitbox SPRITE_ROCKET, i%, 16, 16, 4, 0, 8, 16
    AddSpriteStrip i%, 1, 97, 3, 0, 18
    SetSpriteataWithHitbox SPRITE_BASE, i%, 16, 16, 0, 0, 16, 16
    AddSpriteStrip i%, 37, 97, 3, 0, 18
    SetSpriteData SPRITE_MYSTERY_SCORE, i%, 16, 16
    AddSpriteStrip i%, 73, 97, 3, 0, 18
    SetSpriteataWithHitbox SPRITE_MYSTERY, i%, 16, 16, 0, 0, 16, 16
    AddSpriteStrip i%, 91, 97, 1, 0, 0
    SetSpriteataWithHitbox SPRITE_FUEL, i%, 16, 16, 0, 0, 16, 16
    AddSpriteStrip i%, 91, 115, 1, 0, 0
    SetSpriteData SPRITE_OBJECT_EXPLOSION, i%, 16, 16
    AddSpriteStrip i%, 109, 97, 3, 0, 18
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
    SetSpriteataWithHitbox SPRITE_BULLET, i%, 8, 8, 3, 3, 2, 2
    AddSpriteStrip i%, 181, 201, 1, 0, 0
    SetSpriteData SPRITE_TEXT, i%, 8, 8
    FOR c% = 0 TO 4
        AddSpriteStrip i%, 91, 201 + c% * 30, 9, 9, 0
        AddSpriteStrip i%, 1, 210 + c% * 30, 17, 9, 0
        AddSpriteStrip i%, 1, 201 + c% * 30, 10, 9, 0
        AddSpriteStrip i%, 1, 220 + c% * 30, 1, 9, 0
        AddSpriteStrip i%, 172, 201 + c% * 30, 2, 9, 0
        AddSpriteStrip i%, 154, 210 + c% * 30, 2, 9, 0
    NEXT c%
END SUB

SUB SetSpriteBasics (s%, i%, sw%, sh%)
    spriteData(s%).offset% = i%
    spriteData(s%).size.x% = sw%
    spriteData(s%).size.y% = sh%
END SUB

SUB SetSpriteData (s%, i%, sw%, sh%)
    SetSpriteBasics s%, i%, sw%, sh%
    SetRect spriteData(s%).hitbox, 0, 0, sw%, sh%
END SUB

SUB SetSpriteataWithHitbox (s%, i%, sw%, sh%, x%, y%, w%, h%)
    SetSpriteBasics s%, i%, sw%, sh%
    SetRect spriteData(s%).hitbox, x%, y%, w%, h%
END SUB

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
    FOR i% = 0 TO 27: READ tileU%(i%): NEXT i%
    FOR i% = 0 TO 27: READ tileV%(i%): NEXT i%
    FOR i% = 0 TO 6: READ paletteOrder%(i%): NEXT i%
    FOR i% = 0 TO 6: READ playerExplosionFrameOrder%(i%): NEXT i%
    FOR i% = 0 TO 9: READ place$(i%): NEXT i%
    FOR i% = 0 TO 9: READ placeColour%(i%): NEXT i%
    FOR i% = 0 TO 5: READ scoreTable$(i%): NEXT i%
    DATA 161,11,31,1,21,51,71,41,61,91,111,81,101,131,141,121,151,161,151,1,91,101,71,91,121,141,111,131
    DATA 161,151,151,151,151,151,151,151,151,151,151,151,151,151,151,151,151,151,161,161,161,161,161,161,161,161,161,161
    DATA 0,1,3,4,5,6,7
    DATA 0,1,0,1,0,2,3
    DATA "1ST","2ND","3RD","4TH","5TH","6TH","7TH","8TH","9TH","10TH"
    DATA 3,3,3,2,2,2,4,4,4,4
    DATA " ...  50 PTS     "," ...  80 PTS     "," ... 100 PTS     "," ... 150 PTS     "," ... 800 PTS     "," ... MYSTERY"
END SUB

SUB LoadDataFromROM
    DIM handle&
    handle& = FREEFILE
    OPEN "assets/game-data.bin" FOR BINARY AS #handle& LEN = 1
    mapData$ = SPACE$(LOF(handle&))
    GET #handle&, , mapData$
    CLOSE #handle&
END SUB

'===== High score code ================================================================================================================================================================================

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

SUB InitialiseHiscores
    DIM i%
    FOR i% = 0 TO 9
        hiscores%(i%) = (10 - i%) * 1000
    NEXT i%
END SUB

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
    UpdateStars
    SELECT CASE game.state%
        CASE STATE_TITLE
            IF game.frameCounter& > 8 * game.fps% THEN SetGameState STATE_HIGHSCORES
        CASE STATE_HIGHSCORES
            IF game.frameCounter& > 8 * game.fps% THEN SetGameState STATE_SCORETABLE
        CASE STATE_SCORETABLE
            IF game.frameCounter& > 8 * game.fps% THEN PrepareForLevel: game.lives% = 1: SetGameState STATE_DEMO
        CASE STATE_DEMO
            IF player.state% = PLAYER_FLYING THEN UpdateScroll
            UpdateObjects
            UpdatePlayer
            UpdateAmmo
            UpdateSpawnedSprites
            CalculateCollisions game.scrollOffset% AND 7
            IF LifeLost% THEN SetGameState STATE_TITLE
        CASE STATE_STARTING_GAME
            IF game.frameCounter& > 2.5 * game.fps% THEN SetGameState STATE_PLAY
        CASE STATE_PLAY
            IF player.state% = PLAYER_FLYING THEN UpdateScroll
            UpdateObjects
            UpdatePlayer
            UpdateAmmo
            UpdateSpawnedSprites
            CalculateCollisions game.scrollOffset% AND 7
            IF LifeLost% THEN
                IF game.lives% = 0 THEN SetGameState STATE_GAME_OVER ELSE PrepareForLevel
            END IF
            IF game.stage% = 5 THEN
                IF (game.dataIndex% = LEN(mapData$) + 150 AND game.baseDestroyed%) OR game.dataIndex% = 2 * LEN(mapData$) - stageDataOffset%(game.stage%) + 150 THEN SetGameState STATE_REACHED_BASE
            END IF
        CASE STATE_GAME_OVER
            IF game.frameCounter& > 2 * game.fps% THEN SetGameState STATE_HIGHSCORES
        CASE STATE_REACHED_BASE
            IF game.frameCounter& > 3 * game.fps% THEN
                SetGameState STATE_PLAY
                IF game.baseDestroyed% THEN BaseDefeated ELSE PrepareForLevel
            END IF
    END SELECT
END SUB

SUB UpdateScroll
    DIM i%
    game.scrollOffset% = game.scrollOffset% + 1
    IF (game.scrollOffset% AND 7) = 0 THEN UpdateLandscape
    FOR i% = 0 TO objectCount% - 1: object(i%).sprite.position.x% = object(i%).sprite.position.x% - 1: NEXT i%
    FOR i% = 0 TO spawnedSpriteCount% - 1: spawnedSprite(i%).position.x% = spawnedSprite(i%).position.x% - 1: NEXT i%
END SUB

SUB UpdateFromVirtualScreen
    game.frameCounter& = game.frameCounter& + 1
    _PUTIMAGE , virtualScreen&, 0, (0, 0)-(SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1)
    _DISPLAY
END SUB

'===== Frame render functions =========================================================================================================================================================================

SUB RenderFrame
    RenderStars
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
            RenderLandscape game.scrollOffset% AND 7
            RenderObjects
            RenderPlayer
            RenderAmmo
            RenderSpawnedSprites
            RenderHud
            RenderStartKey
        CASE STATE_STARTING_GAME
            RenderStartingGame
        CASE STATE_PLAY
            RenderLandscape game.scrollOffset% AND 7
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
    UpdateFromVirtualScreen
END SUB

SUB RenderSpawnedSprites
    DIM i%
    FOR i% = spawnedSpriteCount% - 1 TO 0 STEP -1
        RenderSprite spawnedSprite(i%), 40
    NEXT i%
END SUB

SUB RenderHud
    DIM i%, d%
    LINE (0, 0)-(SCREEN_WIDTH - 1, 39), 0, BF
    LINE (0, 240)-(SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1), 0, BF
    RenderScore
    FOR i% = 0 TO 5
        RenderImage SPRITE_STAGE, i%, 16 + i% * 32, 24
        RenderImage SPRITE_STAGE, 6 - (i% <= game.stage%), 16 + i% * 32, 32
    NEXT i%
    RenderText 3, 30, "FUEL", TEXT_YELLOW
    FOR i% = 0 TO game.lives% - 1
        RenderImage SPRITE_LIVE, 0, 16 * i%, 248
    NEXT i%
    FOR i% = 0 TO game.flagCount% - 1
        RenderImage SPRITE_LEVEL_FLAG, 0, 216 - 8 * i%, 248
    NEXT i%
    FOR i% = 0 TO MAX_FUEL / 8 - 1
        d% = player.fuel% - i% * 8
        IF d% < 0 THEN d% = 0 ELSE IF d% > 8 THEN d% = 8
        RenderImage SPRITE_FUEL_BAR, 8 - d%, 64 + 8 * i%, 240
    NEXT i%
END SUB

SUB RenderScore
    DIM s$
    RenderText 3, 0, "1UP", TEXT_WHITE
    RenderText 9, 0, "HIGH SCORE", TEXT_WHITE
    s$ = LTRIM$(STR$(game.score%))
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
    STATIC counter&, pressed%
    IF counter& MOD game.fps% < game.fps% * 0.8 THEN RenderText 4, 31, "PRESS SPACE TO START", TEXT_WHITE
    IF _KEYDOWN(32) THEN pressed% = TRUE ELSE IF pressed% = TRUE THEN pressed% = FALSE: SetGameState STATE_STARTING_GAME
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
    c% = INT(game.frameCounter& / (game.fps% / 16)) - 1
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
    r.cx% = r.x% + r.w% / 2
    r.cy% = r.y% + r.h% / 2
END SUB

'===== Terrain code ===================================================================================================================================================================================

SUB DrawPreStageTerrain
    DIM dataOffset%, column%
    ResetLandscape
    dataOffset% = stageDataOffset%(game.stage%)
    FOR column% = 0 TO NUM_COLUMNS - 1
        AddColumn column%, 0, 0, 20, 11, FillerType%
        game.columnIndex% = game.columnIndex% XOR 1
    NEXT column%
END SUB

SUB NextColumn
    'There's some magic code in here that loops the background for the final level
    DIM i%, o%, d%
    IF game.dataIndex% < LEN(mapData$) THEN
        IF ASC(mapData$, game.dataIndex%) = 255 THEN
            IF game.stage% < 5 THEN
                game.stage% = game.stage% + 1
                game.dataIndex% = game.dataIndex% + 1
            END IF
        END IF
    END IF
    i% = game.dataIndex%
    DO UNTIL i% < LEN(mapData$)
        i% = i% - (LEN(mapData$) - stageDataOffset%(game.stage%))
    LOOP
    AddColumn NUM_COLUMNS, ASC(mapData$, i%), INT(ASC(mapData$, i% + 1) / 2), ASC(mapData$, i% + 2), INT(ASC(mapData$, i% + 3) / 2), FillerType%
    o% = ASC(mapData$, i% + 4)
    d% = TRUE
    IF o% = 8 THEN
        IF ASC(mapData$, i% - 2) = 8 THEN d% = FALSE
    END IF
    IF d% THEN SpawnObjectFromData o%, ASC(mapData$, i% + 5)
    SpawnNonDataObjects
    game.dataIndex% = game.dataIndex% + 6
END SUB

SUB UpdateLandscape
    ScrollLandscapeTiles
    NextColumn
    game.columnIndex% = game.columnIndex% XOR 1
    game.progressPalette% = game.progressPalette% + 1
    IF game.progressPalette% = 64 THEN NextPalette
END SUB

SUB RenderLandscape (offset%)
    DIM i%
    FOR i% = 0 TO NUM_COLUMNS + 1
        _PUTIMAGE (i% * TILE_WIDTH - offset%, 40), column(i%).texture&, ,
    NEXT i%
END SUB

SUB AddColumn (column%, topTileY%, topTile%, bottomTileY%, bottomTile%, fillerTile%)
    DIM i%, handle&, o%
    i% = 0
    handle& = column(column%).texture&
    _DEST handle&
    CLS
    column(column%).top% = topTileY%
    column(column%).bottom% = bottomTileY%
    IF topTile% > 0 THEN
        DO UNTIL i% = topTileY%
            _PUTIMAGE (0, i% * TILE_HEIGHT), spriteSheet&, handle&, (tileU%(fillerTile%), tileV%(fillerTile%))-(tileU%(fillerTile%) + 7, tileV%(fillerTile%) + 7)
            i% = i% + 1
        LOOP
        IF topTile% > 63 THEN topTile% = topTile% - 44
        _PUTIMAGE (0, i% * TILE_HEIGHT), spriteSheet&, handle&, (tileU%(topTile%), tileV%(topTile%))-(tileU%(topTile%) + 7, tileV%(topTile%) + 7)
        i% = i% + 1
    END IF
    i% = bottomTileY%
    IF bottomTile% >= 33 THEN
        'Dealing with the "KONAMI" text on the final level
        o% = spriteData(SPRITE_TEXT).offset% + bottomTile% - 33
        _PUTIMAGE (0, i% * TILE_HEIGHT), spriteSheet&, handle&, (spriteUV(o%).x%, spriteUV(o%).y%)-(spriteUV(o%).x% + spriteData(SPRITE_TEXT).size.x% - 1, spriteUV(o%).y% + spriteData(SPRITE_TEXT).size.y% - 1)
    ELSE
        _PUTIMAGE (0, i% * TILE_HEIGHT), spriteSheet&, handle&, (tileU%(bottomTile%), tileV%(bottomTile%))-(tileU%(bottomTile%) + 7, tileV%(bottomTile%) + 7)
    END IF
    i% = i% + 1
    DO UNTIL i% = NUM_ROWS
        _PUTIMAGE (0, i% * TILE_HEIGHT), spriteSheet&, handle&, (tileU%(fillerTile%), tileV%(fillerTile%))-(tileU%(fillerTile%) + 7, tileV%(fillerTile%) + 7)
        i% = i% + 1
    LOOP
    _DEST virtualScreen&
END SUB

SUB ResetLandscape
    game.columnIndex = 0
END SUB

SUB ScrollLandscapeTiles
    DIM i%, columnCache AS COLUMN
    columnCache = column(0)
    FOR i% = 0 TO NUM_COLUMNS - 1
        column(i%) = column(i% + 1)
    NEXT i%
    column(NUM_COLUMNS) = columnCache
END SUB

FUNCTION FillerType%
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
        CASE PLAYER_FLYING
            player.sprite.frame% = INT(game.frameCounter& / 8) MOD 3
            IF player.fuel% > 0 THEN
                player.fuelCounter% = player.fuelCounter% - 1
                IF player.fuelCounter% = 0 THEN
                    player.fuelCounter% = player.fuelSpeed%
                    player.fuel% = player.fuel% - 1
                    IF player.fuel% = 20 THEN
                        PlaySfxLooping SFX_FUEL_WARNING
                    END IF
                END IF
            END IF
            IF game.state% = STATE_PLAY THEN
                IF player.fuel% > 0 THEN
                    player.sprite.position.x% = player.sprite.position.x% + _KEYDOWN(KEYDOWN_LEFT) - _KEYDOWN(KEYDOWN_RIGHT)
                    player.sprite.position.y% = player.sprite.position.y% + _KEYDOWN(KEYDOWN_UP) - _KEYDOWN(KEYDOWN_DOWN)
                ELSE
                    player.sprite.position.y% = player.sprite.position.y% + 1
                END IF
                IF player.sprite.position.x% < 8 THEN player.sprite.position.x% = 8 ELSE IF player.sprite.position.x% > SCREEN_WIDTH / 2 - 24 THEN player.sprite.position.x% = SCREEN_WIDTH / 2 - 24
                IF player.sprite.position.y% < 0 THEN player.sprite.position.y% = 0 ELSE IF player.sprite.position.y% > GAME_HEIGHT - 16 THEN player.sprite.position.y% = GAME_HEIGHT - 16
                IF player.firePause% = 0 THEN
                    IF _KEYDOWN(KEYDOWN_FIRE) THEN
                        IF NOT player.firePressed% THEN
                            player.firePressed% = TRUE
                            player.firePause = 4
                            PlaySfx SFX_LASER
                            CreateAmmo AMMO_BULLET
                        END IF
                    ELSE
                        player.firePressed% = FALSE
                    END IF
                ELSE
                    player.firePause% = player.firePause% - 1
                END IF
                IF player.bombPause% = 0 THEN
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

        CASE PLAYER_SPAWNING
            player.state% = PLAYER_FLYING
            game.lives% = game.lives% - 1
            PlaySfxLooping SFX_ENGINE
    END SELECT
END SUB

SUB RenderPlayer
    IF player.state% = PLAYER_FLYING THEN RenderSprite player.sprite, 40
END SUB

SUB DestroyPlayer
    player.state% = PLAYER_EXPLODING
    SpawnSprite SPRITE_PLAYER_EXPLOSION, player.sprite.position: PlaySfx SFX_EXPLOSION
END SUB

'===== Game enemy object handling =====================================================================================================================================================================

SUB UpdateObjects
    DIM i%
    FOR i% = objectCount% - 1 TO 0 STEP -1
        object(i%).sprite.counter% = object(i%).sprite.counter% + 1
        SELECT CASE object(i%).sprite.spriteId%
            CASE TYPE_MISSILE: UpdateMissile (i%)
            CASE TYPE_UFO: UpdateUfo (i%)
            CASE TYPE_BASE: UpdateBase (i%)
            CASE TYPE_METEOR: UpdateMeteor (i%)
        END SELECT
        IF object(i%).sprite.position.x% < -15 OR object(i%).sprite.position.y% < -15 THEN RemoveObject (i%)
    NEXT i%
END SUB

SUB UpdateMissile (i%)
    IF object(i%).inFlight THEN
        object(i%).sprite.position.y% = object(i%).sprite.position.y% - 1
        object(i%).sprite.frame% = 1 + (INT(object(i%).sprite.counter% / 8) AND 1)
    ELSE
        IF NOT (game.stage% = 1 OR game.stage% = 2) THEN
            IF game.state% = STATE_DEMO THEN
                IF object(i%).sprite.position.x% = 40 THEN object(i%).inFlight% = TRUE
            ELSE
                IF object(i%).sprite.position.x% = NUM_COLUMNS * 4 THEN
                    IF RND < 0.25 THEN object(i%).inFlight% = TRUE
                ELSEIF object(i%).sprite.position.x% < NUM_COLUMNS * 4 THEN
                    IF RND < 0.01 THEN object(i%).inFlight% = TRUE
                END IF
            END IF
        END IF
    END IF
END SUB

SUB UpdateBase (i%)
    object(i%).sprite.frame% = INT(object(i%).sprite.counter% / 8) MOD 3
END SUB

SUB UpdateMeteor (i%)
    object(i%).sprite.position.x% = object(i%).sprite.position.x% - 3
    object(i%).sprite.frame% = INT(object(i%).sprite.counter% / 8) AND 3
END SUB

SUB UpdateUfo (i%)
    object(i%).sprite.position.y% = GAME_HEIGHT / 2 - 8 + 32 * SIN(_D2R(object(i%).sprite.counter% * 6))
END SUB

SUB RenderObjects
    DIM i%
    FOR i% = 0 TO objectCount% - 1
        RenderSprite object(i%).sprite, 40
    NEXT i%
END SUB

SUB RemoveObject (i%)
    object(i%) = object(objectCount% - 1)
    objectCount% = objectCount% - 1
END SUB

SUB DestroyObject (i%)
    DIM d%
    SELECT CASE object(i%).sprite.spriteId%
        CASE TYPE_METEOR: EXIT SUB
        CASE TYPE_MISSILE: SpawnSprite SPRITE_OBJECT_EXPLOSION, object(i%).sprite.position: d% = 50 - 30 * object(i%).inFlight%: PlaySfx SFX_ROCKET_EXPLOSION
        CASE TYPE_FUEL: SpawnSprite SPRITE_OBJECT_EXPLOSION, object(i%).sprite.position: d% = 150: player.fuel% = player.fuel% + 15: PlaySfx SFX_EXPLOSION: IF player.fuel% > 20 THEN StopSfx SFX_FUEL_WARNING: IF player.fuel% > MAX_FUEL THEN player.fuel% = MAX_FUEL
        CASE TYPE_MYSTERY: d% = INT(RND * 3): SpawnSprite SPRITE_MYSTERY_SCORE, object(i%).sprite.position: spawnedSprite(spawnedSpriteCount% - 1).frame% = d%: d% = (d% + 1) * 100: PlaySfx SFX_EXPLOSION
        CASE TYPE_BASE: SpawnSprite SPRITE_OBJECT_EXPLOSION, object(i%).sprite.position: d% = 800: PlaySfx SFX_EXPLOSION: game.baseDestroyed% = TRUE
        CASE TYPE_UFO: SpawnSprite SPRITE_UFO_EXPLOSION, object(i%).sprite.position: d% = 100: PlaySfx SFX_ROCKET_EXPLOSION
    END SELECT
    IF game.state% = STATE_PLAY THEN IncreaseScore (d%)
    RemoveObject i%
END SUB

'===== Background stars ===============================================================================================================================================================================

SUB UpdateStars
    stars.counter% = stars.counter% + 1
    IF stars.counter% >= game.fps% THEN
        stars.counter% = 0
        stars.frame% = stars.frame% + 1
        IF stars.frame% = 4 THEN stars.frame% = 1
    END IF
END SUB

SUB RenderStars
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
    FOR i% = ammoCount% - 1 TO 0 STEP -1
        SELECT CASE ammo(i%).spriteId%
            CASE AMMO_BULLET:
                ammo(i%).position.x% = ammo(i%).position.x% + 4
                IF ammo(i%).position.x% > SCREEN_WIDTH THEN
                    ammo(i%) = ammo(ammoCount% - 1)
                    ammoCount% = ammoCount% - 1
                END IF
            CASE AMMO_BOMB:
                SELECT CASE ammo(i%).counter%
                    CASE 0: ammo(i%).frame% = 0
                    CASE 4: ammo(i%).frame% = 1
                    CASE 8: ammo(i%).frame% = 0
                    CASE 16: ammo(i%).frame% = 2
                    CASE 28: ammo(i%).frame% = 3
                    CASE 40: ammo(i%).frame% = 4
                END SELECT
                SELECT CASE ammo(i%).counter%
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

FUNCTION BombCount%
    DIM c%, i%
    FOR i% = 0 TO ammoCount% - 1
        c% = c% - (ammo(i%).spriteId% = AMMO_BOMB)
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
    IF player.state% = PLAYER_FLYING THEN
        IF CheckMapCollision%(xOffset%, player.sprite.position.x% + 8, player.sprite.position.y%, PLAYER_WIDTH - 8, PLAYER_HEIGHT) THEN DestroyPlayer ELSE IF CheckObjectCollision% THEN DestroyPlayer
    END IF
    CheckAmmoCollisions xOffset%
END SUB

FUNCTION CheckMapCollision% (xOffset%, x%, y%, w%, h%)
    DIM cLeft%, cRight%, cTop%, cBottom%, i%
    cLeft% = INT((x% + xOffset%) / TILE_WIDTH)
    cRight% = INT((x% + w% - 1 + xOffset%) / TILE_WIDTH)
    cTop% = INT(y% / TILE_HEIGHT)
    cBottom% = INT((y% + h% - 1) / TILE_HEIGHT)
    FOR i% = cLeft% TO cRight%
        IF cTop% < column(i%).top% OR cBottom% > column(i%).bottom% THEN CheckMapCollision% = TRUE: EXIT FUNCTION
    NEXT i%
    CheckMapCollision% = FALSE
END FUNCTION

FUNCTION CheckObjectCollision%
    DIM i%
    FOR i% = 0 TO objectCount% - 1
        IF SpriteCollision%(player.sprite, object(i%).sprite) THEN DestroyObject i%: CheckObjectCollision% = TRUE: EXIT FUNCTION
    NEXT i%
    CheckObjectCollision% = FALSE
END FUNCTION

SUB CheckAmmoCollisions (xOffset%)
    DIM c%, i%, o%, p%
    FOR o% = objectCount% - 1 TO 0 STEP -1
        FOR i% = ammoCount% - 1 TO 0 STEP -1
            IF SpriteCollision%(ammo(i%), object(o%).sprite) THEN DestroyObject o%: DestroyAmmo (i%): EXIT FOR
        NEXT i%
    NEXT o%
    FOR i% = ammoCount% - 1 TO 0 STEP -1
        c% = INT(((ammo(i%).position.x% + spriteData(ammo(i%).spriteId%).hitbox.cx%) + xOffset%) / TILE_WIDTH)
        p% = ammo(i%).position.y% + spriteData(ammo(i%).spriteId%).hitbox.cy%
        IF p% - 2 < column(c%).top% * TILE_HEIGHT OR p% + 2 > column(c%).bottom% * TILE_HEIGHT THEN DestroyAmmo (i%)
    NEXT i%
END SUB

FUNCTION SpriteCollision% (s1 AS SPRITE, s2 AS SPRITE)
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
    SetPalette (game.currentPalette% + 1) MOD 7
END SUB

'===== Game utility functions =========================================================================================================================================================================

SUB IncreaseScore (d%)
    game.score% = game.score% + d%
    IF game.score% >= 10000 AND game.score% - d% < 10000 THEN game.lives% = game.lives% + 1
    IF game.score% > game.hiscore% THEN game.hiscore% = game.score%
END SUB

SUB PrepareForLevel
    objectCount% = 0
    spawnedSpriteCount% = 0
    ammoCount% = 0
    player.state% = PLAYER_SPAWNING
    player.fuelCounter% = player.fuelSpeed%
    player.fuel% = MAX_FUEL
    SetPalette 0
    game.scrollOffset% = 0
    game.dataIndex = stageDataOffset%(game.stage%)
    game.baseDestroyed% = FALSE
    DrawPreStageTerrain
    NextColumn
    UpdateScroll
    SetSprite player.sprite, SPRITE_PLAYER, 8, 40
    StopSfx SFX_FUEL_WARNING
    StopSfx SFX_ENGINE
END SUB

FUNCTION LifeLost%
    LifeLost% = (player.state% = PLAYER_EXPLODING) AND spawnedSpriteCount% = 0
END FUNCTION

SUB BaseDefeated
    game.stage% = 0
    PrepareForLevel
    player.fuelSpeed% = player.fuelSpeed% - 1
    game.flagCount% = game.flagCount% + 1
END SUB

SUB SetGameState (s%)
    game.state% = s%
    game.frameCounter& = 0
    IF s% = STATE_TITLE THEN game.stage% = 0: player.fuelSpeed% = INITIAL_FUEL_SPEED
    IF s% = STATE_STARTING_GAME THEN game.lives% = 3: game.score% = 0: game.hiscore% = hiscores%(0): game.flagCount% = 1: PrepareForLevel: PlaySfx SFX_START_GAME
    IF s% = STATE_GAME_OVER THEN StopSfx SFX_FUEL_WARNING: StopSfx SFX_ENGINE: CheckScore
    IF s% = STATE_REACHED_BASE THEN StopSfx SFX_FUEL_WARNING: StopSfx SFX_ENGINE
END SUB

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
    stageDataOffset%(0) = dataOffset%
    stage% = 1
    DO UNTIL stage% = NUM_STAGES
        dataOffset% = dataOffset% + 6
        IF ASC(mapData$, dataOffset%) = 255 THEN
            dataOffset% = dataOffset% + 1
            stageDataOffset%(stage%) = dataOffset%
            stage% = stage% + 1
        END IF
    LOOP
END SUB

SUB SpawnObjectFromData (positionY%, objectType%)
    IF positionY% = 0 OR objectType% > 15 THEN EXIT SUB
    SpawnObject positionY%, LOG(objectType%) / LOG(2)
END SUB

SUB SpawnObject (positionY%, objectType%)
    SetSprite object(objectCount%).sprite, objectType%, NUM_COLUMNS * TILE_WIDTH, positionY% * TILE_HEIGHT
    object(objectCount%).inFlight% = FALSE
    objectCount% = objectCount% + 1
END SUB

SUB SpawnNonDataObjects
    IF game.stage% = 1 THEN
        IF ((game.dataIndex% - stageDataOffset%(game.stage%)) / 6) MOD 10 = 0 AND game.dataIndex% < stageDataOffset%(2) - NUM_COLUMNS * 6 THEN SpawnObject 0, TYPE_UFO
    ELSEIF game.stage% = 2 THEN
        IF ((game.dataIndex% - stageDataOffset%(game.stage%)) / 6) MOD 2 = 0 AND game.dataIndex% < stageDataOffset%(3) - NUM_COLUMNS * 6 THEN SpawnObject RND * (NUM_ROWS - 11) + 1, TYPE_METEOR
    END IF
END SUB

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


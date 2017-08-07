module Util
  ( checkForMouseSupport
  , resizeCanvas
  , setTool
  , setFgPaletteIndex
  , setBgPaletteIndex
  , toggleHud
  , beginFgPaletteSelect
  , beginBgPaletteSelect
  , beginToolSelect
  , setMode

  , tools

  , beginCharacterSelect
  , cancelCharacterSelect
  , selectCharacter
  )
where

import Control.Monad (when)
import Control.Monad.Trans (liftIO)
import qualified Graphics.Vty as V
import qualified Data.Vector as Vec
import System.Exit (exitFailure)
import Lens.Micro.Platform

import Brick

import Types

tools :: [(Tool, Int)]
tools =
    [ (FreeHand, 1)
    , (Eraser, 0)
    ]

setMode :: Mode -> AppState -> AppState
setMode m s = s & mode .~ m

beginToolSelect :: AppState -> AppState
beginToolSelect s =
    if s^.showHud
    then setMode ToolSelect s
    else s

beginFgPaletteSelect :: AppState -> AppState
beginFgPaletteSelect s =
    if s^.showHud
    then setMode FgPaletteEntrySelect s
    else s

beginBgPaletteSelect :: AppState -> AppState
beginBgPaletteSelect s =
    if s^.showHud
    then setMode BgPaletteEntrySelect s
    else s

setTool :: AppState -> Tool -> AppState
setTool s t = s & tool .~ t

setFgPaletteIndex :: AppState -> Int -> AppState
setFgPaletteIndex s i = setMode Main $ s & drawFgPaletteIndex .~ i

setBgPaletteIndex :: AppState -> Int -> AppState
setBgPaletteIndex s i = setMode Main $ s & drawBgPaletteIndex .~ i

beginCharacterSelect :: AppState -> AppState
beginCharacterSelect = setMode CharacterSelect

cancelCharacterSelect :: AppState -> AppState
cancelCharacterSelect = setMode Main

selectCharacter :: Char -> AppState -> AppState
selectCharacter c s = setMode Main $ s & drawCharacter .~ c

toggleHud :: AppState -> AppState
toggleHud s = s & showHud %~ not

checkForMouseSupport :: IO ()
checkForMouseSupport = do
    vty <- V.mkVty =<< V.standardIOConfig

    when (not $ V.supportsMode (V.outputIface vty) V.Mouse) $ do
        putStrLn "Error: this terminal does not support mouse interaction"
        exitFailure

    V.shutdown vty

resizeCanvas :: AppState -> EventM n AppState
resizeCanvas s = do
    vty <- getVtyHandle
    newSz <- liftIO $ V.displayBounds $ V.outputIface vty

    -- If the new bounds are different than the old, create a new array
    -- and copy.
    case newSz /= s^.canvasSize of
        False -> return s
        True -> liftIO $ do
            -- Create a new draw array with the right bounds
            let copyCell rowVec col =
                    if col < Vec.length rowVec
                    then Vec.unsafeIndex rowVec col
                    else blankPixel
                copyRow row = Vec.generate (newSz^._1)
                              (if row < Vec.length (s^.drawing)
                               then copyCell (Vec.unsafeIndex (s^.drawing) row)
                               else const blankPixel)
                newDraw = if s^.canvasSize == (0, 0)
                          then Vec.replicate (newSz^._2) $
                               Vec.replicate (newSz^._1) blankPixel
                          else Vec.generate (newSz^._2) copyRow

            return $ s & drawing .~ newDraw
                       & canvasSize .~ newSz

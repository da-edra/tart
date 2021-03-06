module UI.CanvasSizePrompt
  ( drawCanvasSizePromptUI
  )
where

import qualified Data.Text as T
import Lens.Micro.Platform

import Brick
import Brick.Focus
import Brick.Widgets.Border
import Brick.Widgets.Center
import Brick.Widgets.Edit

import Types

drawCanvasSizePromptUI :: AppState -> [Widget Name]
drawCanvasSizePromptUI s = [drawPromptWindow s]

drawPromptWindow :: AppState -> Widget Name
drawPromptWindow s =
    centerLayer $
    borderWithLabel (str "Resize Canvas") $
        hLimit 40 $
        padLeftRight 2 $ padTopBottom 1 body
    where
        body = padBottom (Pad 1) width <=> height
        renderString = txt . T.unlines
        width = str "Width: "  <+>
                (clickable CanvasSizeWidthEdit $
                 withFocusRing (s^.canvasSizeFocus) (renderEditor renderString) (s^.canvasSizeWidthEdit))
        height = str "Height: " <+>
                (clickable CanvasSizeHeightEdit $
                 withFocusRing (s^.canvasSizeFocus) (renderEditor renderString) (s^.canvasSizeHeightEdit))

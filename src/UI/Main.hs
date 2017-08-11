module UI.Main
  ( drawMainUI
  , toolSelectorEntryWidth
  )
where

import Brick
import Brick.Widgets.Border
import Brick.Widgets.Border.Style
import Brick.Widgets.Center
import Data.Monoid ((<>))
import Data.Maybe (isJust)
import qualified Graphics.Vty as V
import Lens.Micro.Platform

import Types
import UI.Common
import Theme
import Util
import Canvas

drawMainUI :: AppState -> [Widget Name]
drawMainUI s =
    [ topHud s
    , bottomHud s
    , canvas s
    ]

topHud :: AppState -> Widget Name
topHud s =
    let fgPal = drawPaletteSelector s True
        bgPal = drawPaletteSelector s False
        toolbarEntries = [ padLeft (Pad 1) $ drawToolSelector s
                         , fgPal
                         , bgPal
                         , drawCanvasSize s
                         ]
        filename = case s^.canvasPath of
            Nothing -> "<unsaved>"
            Just p -> p
        modified = if not $ s^.canvasDirty then "" else "*"
    in clickable TopHud $
       vBox [ hCenter $ padLeft (Pad 1) $ hBox $ padRight (Pad 1) <$> toolbarEntries
            , hBox [borderElem bsHorizontal <+> str ("[" <> filename <> modified <> "]") <+> hBorder]
            ]

bottomHud :: AppState -> Widget Name
bottomHud s =
    let toolHuds = [ (Freehand, freehandHud)
                   , (FloodFill, floodfillHud)
                   ]
    in case lookup (s^.tool) toolHuds of
        Nothing -> emptyWidget
        Just f ->
            Widget Fixed Fixed $ do
                ctx <- getContext
                let hOff = ctx^.availHeightL - 4
                render $
                    translateBy (Location (0, hOff)) $
                    clickable BottomHud $
                    hBorderWithLabel (str $ toolName $ s^.tool) <=>
                    (hCenter $ f s)

freehandHud :: AppState -> Widget Name
freehandHud s = drawChar s

floodfillHud :: AppState -> Widget Name
floodfillHud s = drawChar s

drawCanvasSize :: AppState -> Widget Name
drawCanvasSize s =
    let (width, height) = canvasSize $ s^.drawing
    in clickable ResizeCanvas $
       borderWithLabel (str "Can" <+> (withDefAttr keybindingAttr (str "v")) <+> str "as") $
       str $ show width <> " columns, " <> show height <> " rows"

drawChar :: AppState -> Widget Name
drawChar s =
    clickable CharSelector $
    borderWithLabel ((withDefAttr keybindingAttr $ str "C") <+> str "har") $
    padLeftRight 2 $ str [s^.drawCharacter]

toolSelectorEntryWidth :: Int
toolSelectorEntryWidth = 20

drawToolSelector :: AppState -> Widget Name
drawToolSelector s =
    let Just idx = lookup (s^.tool) tools
    in clickable ToolSelector $
       borderWithLabel ((withDefAttr keybindingAttr $ str "T") <+> str "ool") $
       hLimit toolSelectorEntryWidth $
       hCenter $
       (withDefAttr keybindingAttr (str $ show idx)) <+>
       (str $ ":" <> toolName (s^.tool))

drawPaletteSelector :: AppState -> Bool -> Widget Name
drawPaletteSelector s isFg =
    (clickable selName $ borderWithLabel label curColor)
    where
        label = if isFg
                then (withDefAttr keybindingAttr $ str "F") <+> str "G"
                else (withDefAttr keybindingAttr $ str "B") <+> str "G"
        curIdx = if isFg then s^.drawFgPaletteIndex
                         else s^.drawBgPaletteIndex
        selName = if isFg then FgSelector else BgSelector
        curColor = drawPaletteEntry s curIdx 4 isFg

canvas :: AppState -> Widget Name
canvas s =
    centerAbout (s^.canvasOffset) $
    updateAttrMap (applyAttrMappings [(borderAttr, fg V.white)]) $
    border $
    clickable Canvas $
    raw $ canvasToImage (s^.drawing) (shouldUseOverlay s) (s^.drawingOverlay)

shouldUseOverlay :: AppState -> Bool
shouldUseOverlay s =
    isJust $ s^.dragging

canvasToImage :: Canvas -> Bool -> Canvas -> V.Image
canvasToImage a useOverlay overlay =
    let (lastCol, lastRow) = canvasSize a & each %~ pred
        blank = decodePixel blankPixel
        rows = getRow <$> [0..lastRow]
        getRow r = V.horizCat $ (uncurry $ flip V.char) <$> getCol r <$> [0..lastCol]
        getCol r c = if useOverlay
                     then let oPix = canvasGetPixel overlay (c, r)
                          in if oPix == blank
                             then canvasGetPixel a (c, r)
                             else oPix
                     else canvasGetPixel a (c, r)
    in V.vertCat rows

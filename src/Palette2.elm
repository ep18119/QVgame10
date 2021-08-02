port module Palette2 exposing (..)

import Browser
import Html exposing (Html, Attribute, div, input, text, button)
import Html.Attributes exposing (style, placeholder, value) 
import Html.Events.Extra.Mouse as Mouse
import Svg
import Svg.Attributes exposing (d, stroke, fill, strokeWidth, width, height, viewBox, x, y)
import Dict
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy, lazy2, lazy3, lazy4, lazy5)

import Html.Events exposing (onClick, stopPropagationOn, targetValue)
import Json.Decode as Json
import Json.Encode as Encode

port sendMes : String -> Cmd msg

-- MAIN

main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
            
-- MODEL 

type alias Magnitude = Float

type alias Position = (Magnitude, Magnitude)

type BrickType 
    = BasicBrick
    | EntryBrick
    | TailBrick
    | CaseBrick    

type BrickCommand 
    = CommandNOP -- "動作開始"
    | CommandMove -- "n歩前進する"
    | CommandTurnRight -- "n度右回りする"
    | CommandTurnLeft -- "n度左回りする"
    | CommandTurnBack -- "左右反転する"
    | CommandTurnSet -- "向きをn度にする"
     --CommandResetXY -- "座標(0,0)に移動"
    | CommandSetX -- "x座標をnにする"
    | CommandChangeX -- "x座標をnずつ変える"
    | CommandSetY -- "y座標をnにする"
    | CommandChangeY -- "y座標をnずつ変える"
    | CommandDownPen -- "ペンを下げる"
    | CommandUpPen -- "ペンを上げる"
    | CommandFuncStart -- "関数nを開始"
    | CommandFuncStop -- "関数nへ移動"
    | CommandIf -- "if制御"
    | CommandIfS
    | CommandIfR
    | CommandIfL
    | CommandIfB
    | CommandNone
    | CommandReboot -- 繰り返し

-- 引数情報
type alias Argument
    = { disp : String --引数の有無 及び 引数の横に表示する文字列
      , value : String --引数
      }

type alias Node
    = { getBrickType : BrickType 
      , getBrickCommand : BrickCommand
      , getBrickArgument : Argument
      }

-- 抽象構文木（AST）
type AST a
    = Nil
    | AST a
          (AST a) -- bottom (left)
          (AST a) -- right

-- 非空（non-empty）のAST
type ASTne a
    = ASTne a (AST a) (AST a)

-- 根の位置情報付きのAST
type ASTxy a
    = ASTxy 
        Position -- 根の座標
        (ASTne a)              -- 非空に限定 





type alias DnDInfo 
    = { getOnDnD : Bool                  -- DnDの最中は真 
      , getXY0 : Position  -- DnD開始時点のマウスの座標（event.offsetPos）
      , getBrickXY : Position -- 移動中ブロックの移動前の座標
      , getMoveXY : Position -- ドラッグ中のブロックの座標
      }
      
type alias Model 
    = { getBrickSize : Magnitude
      , getASTRoots : List (ASTxy Node) 
      , getDnDInfo: DnDInfo
      }

-- ブロック間の間隔
-- 凹凸の分を除くのでブロックサイズの90%
interval : Model -> Magnitude
interval model = model.getBrickSize * 0.9

-- 位置比較時のマージン
mergin : Magnitude
mergin = 20

init : () -> (Model, Cmd Msg)
init flags = (
    { getBrickSize = 128
    , getASTRoots = 
        [ --ASTxy
        --    (30, 630)
        --    ( ASTne 
        --        { getBrickType = EntryBrick
        --        , getBrickCommand = CommandFuncStart
        --        , getBrickArgument = {disp = "", value = ""}
        --        }
        --        Nil 
        --        ( AST
        --            { getBrickType = TailBrick
        --            , getBrickCommand = CommandFuncStop
        --            , getBrickArgument = {disp = "", value = ""}
        --            } Nil Nil
        --        )
        --    )
        --,
          ASTxy
            (30, 30)
            ( ASTne
                { getBrickType = BasicBrick
                , getBrickCommand = CommandMove
                , getBrickArgument = {disp = "", value = ""}
                } Nil Nil
            )    
        , ASTxy
            (180, 180)
            ( ASTne
                { getBrickType = BasicBrick
                , getBrickCommand = CommandTurnRight
                , getBrickArgument = {disp = "", value = ""}
                } Nil Nil
            )    
        , ASTxy
            (30, 180)
            ( ASTne
                { getBrickType = BasicBrick
                , getBrickCommand = CommandTurnLeft
                , getBrickArgument = {disp = "", value = ""}
                } Nil Nil
            )    
        , ASTxy
            (180, 30)
            ( ASTne
                { getBrickType = BasicBrick
                , getBrickCommand = CommandTurnBack
                , getBrickArgument = {disp = "", value = ""}
                } Nil Nil
            )
        , ASTxy
            (30, 330)
            ( ASTne
                { getBrickType = CaseBrick
                , getBrickCommand = CommandIfS
                , getBrickArgument = {disp = "", value = ""}
                } Nil Nil
            )
        , ASTxy
            (180, 480)
            ( ASTne
                { getBrickType = CaseBrick
                , getBrickCommand = CommandIfR
                , getBrickArgument = {disp = "", value = ""}
                } Nil Nil
            )
        , ASTxy
            (30, 480)
            ( ASTne
                { getBrickType = CaseBrick
                , getBrickCommand = CommandIfL
                , getBrickArgument = {disp = "", value = ""}
                } Nil Nil
            )
        , ASTxy
            (180, 330)
            ( ASTne
                { getBrickType = CaseBrick
                , getBrickCommand = CommandIfB
                , getBrickArgument = {disp = "", value = ""}
                } Nil Nil
            )
        , ASTxy
            (30, 780)
            ( ASTne
                { getBrickType = BasicBrick
                , getBrickCommand = CommandNone
                , getBrickArgument = {disp = "", value = ""}
                } Nil Nil
            )
        , ASTxy
            (30, 630)
            ( ASTne
                { getBrickType = TailBrick
                , getBrickCommand = CommandReboot
                , getBrickArgument = {disp = "", value = ""}
                } Nil Nil
            )
        , ASTxy
            (180, 630)
            ( ASTne
                { getBrickType = TailBrick
                , getBrickCommand = CommandFuncStop
                , getBrickArgument = {disp = "", value = ""}
                } Nil Nil
            )
        ]
    , getDnDInfo = 
        { getOnDnD = False
        , getXY0 = (0, 0)
        , getBrickXY = (0, 0)
        , getMoveXY = (0, 0)
        }
    }   
    , Cmd.none )


-- エンコード用 BrikcTypeを文字列に変換
encodeBrickType : BrickType -> Encode.Value
encodeBrickType bt =
  Encode.string (
    case bt of
      EntryBrick -> "EntryBrick"
      BasicBrick -> "BasicBrick"
      TailBrick -> "TailBrick"
      CaseBrick -> "CaseBrick"
  )
   
-- エンコード用 BrickCommandを文字列に変換
encodeBrickCommand : BrickCommand -> Encode.Value
encodeBrickCommand bc =
  Encode.string (
    case bc of
      CommandNOP -> "CommandNOP"
      CommandMove -> "CommandMove"
      CommandTurnRight -> "CommandTurnRight"
      CommandTurnLeft -> "CommandTurnLeft"
      CommandTurnBack -> "CommandTurnBack"
      CommandTurnSet -> "CommandTurnSet"
      CommandSetX -> "CommandSetX"
      CommandChangeX -> "CommandChangeX"
      CommandSetY -> "CommandSetY"
      CommandChangeY -> "CommandChangeY"
      CommandDownPen -> "CommandDownPen"
      CommandUpPen -> "CommandUpPen"
      CommandFuncStart -> "CommandFuncStart"
      CommandFuncStop -> "CommandFuncStop"
      CommandIf -> "CommandIf"
      CommandIfS -> "CommandIfS"
      CommandIfR -> "CommandIfR"
      CommandIfL -> "CommandIfL"
      CommandIfB -> "CommandIfB"
      CommandNone -> "CommandNone"
      CommandReboot -> "CommandReboot"
  )

-- ブロック単位のエンコード
-- CaseBrickの場合、Argument.dispも追加して前置記法の形にする
encodeAST : AST Node -> Encode.Value
encodeAST ast =
  case ast of
    Nil ->
      Encode.string "Nil"
    AST node bottom right ->
      Encode.object
        [ ( "node", Encode.object
            [ ( "getBrickType", encodeBrickType node.getBrickType)
            , ( "getBrickCommand", encodeBrickCommand node.getBrickCommand)
            , ( "getBrickArgument", Encode.string (
                  if node.getBrickType == CaseBrick then
                      (String.reverse node.getBrickArgument.disp) ++ " " ++ node.getBrickArgument.value
                  else
                      node.getBrickArgument.value
                  )
              )
            ])
        , ("bottom", encodeAST bottom)
        , ("right", encodeAST right)
        ]

-- 構文木単位のエンコード
-- 葉は全てencodeASTでエンコードする
encodeASTxy : ASTxy Node -> Encode.Value
encodeASTxy (ASTxy pos (ASTne node astb astr)) =
  encodeAST (AST node astb astr)

-- 全体のエンコード
-- 構文木をエンコードしたものをリスト化し、そのリストをエンコードする
encodeASTRoots : Model -> Encode.Value
encodeASTRoots model =
  List.map encodeASTxy model.getASTRoots 
  |> Encode.list (\a -> a)

--ブロック単体のエンコード
--encodeBrickCommand関数を使いたいのでpaletteとeditorも個別でエンコードする
encodeTheBrick : BrickCommand -> Encode.Value
encodeTheBrick command =
    [ Encode.string "palette"
    , Encode.string "editor"
    , encodeBrickCommand command
    ]
    |> Encode.list (\a -> a) 

-- UPDATE

type Msg = MsgCloneUs (ASTne Node) Mouse.Event
         | MsgLetMeRoot (ASTne Node) Position Mouse.Event
         | MsgMoveUs Mouse.Event
         | MsgAttachMe (ASTxy Node) Position Mouse.Event
         | MsgStartDnD (ASTxy Node) Mouse.Event         
         | MsgInputChanged Position String String
         | Dummy Mouse.Event
         | OpenWindow
         | Encoding
         | SendCommand Mouse.Event BrickCommand

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = 
    case msg of
        MsgCloneUs ast event -> 
            (cloneUs ast event model, Cmd.none)
        -- 根ではMsgLetMeRootは生じないので単独のMsgStartDnDは必要
        MsgStartDnD (ASTxy xy (ASTne n b r)) event ->
            if n.getBrickCommand == CommandNOP then (model, Cmd.none)
            else (startDnDxy (ASTxy xy (ASTne n b r)) event model, Cmd.none)
        MsgLetMeRoot ast xy event ->
            (letMeRoot ast event model |> startDnD event, Cmd.none)
        MsgMoveUs event ->
            (moveUs event model, Cmd.none)
        MsgAttachMe astxy xy1 event ->
            (attachMe astxy xy1 event model |> stopDnD event, Cmd.none)
        MsgInputChanged xy argCode value ->
            (inputValuexy xy argCode value model, Cmd.none)
        -- 実質なにもしない stopDnDはバグ回避用
        Dummy event ->
            (stopDnD event model, Cmd.none)
        -- ウィンドウ表示の指示をhtmlに送る
        OpenWindow ->
            (model, sendMes "Open")
        -- エンコードした情報をhtmlに送る
        Encoding ->
            (model, sendMes (Encode.encode 2 (encodeASTRoots model)))
        SendCommand event command ->
            ( model
            , sendMes (Encode.encode 2 (encodeTheBrick command))
            )

-- ASTへの処理で更新があったかどうかの判定で使用
type Change = Changed | Unchanged

cor : Change -> Change -> Change
cor a b = 
    case (a, b) of
        (Unchanged, Unchanged) -> 
            Unchanged
        (_ ,_ ) ->
            Changed   

-- Writerアプリカティブ
-- elmには型クラスがないのでChangeモノイドに特化
type alias W a = (a, Change)

-- 使用例: 
-- absW x = if x > 0 then (x, Unchanged) else (-x, Changed)
-- unit (+) |> andMap (absW 1) |> andMap (absW -2)  ==> (3, Changed)
-- unit (+) |> andMap (absW 1) |> andMap (absW 2)   ==> (3, Unchanged)
andMap : W a -> W (a -> b) -> W b
andMap (a, c) (f, d) = (f a, cor c d)

unit : a -> W a
unit a = (a, Unchanged)

-- リストの各要素に関数fを作用させ（List.mapと同じ），その過程で
-- 変更が生じたかどうかを合わせて返す
-- 使用例：
-- absW x = if x > 0 then (x, Unchanged) else (-x, Changed)
-- listMapW absW [1, -2, 3, -4, 5]  ==>  ([1, 2, 3, 4, 5], Changed)
-- listMapW absW [1, 2, 3, 4, 5]    ==>  ([1, 2, 3, 4, 5], Unchanged)
listMapW : (a -> W a) -> List a -> W (List a) 
listMapW f = List.foldr (\a mbs -> unit (::) |> andMap (f a) |> andMap mbs)
                        (unit [])           

-- ペア（2組）の各要素毎に2項演算を作用させる
-- 使用例： pairMap2 (+) (1, 10) (2, 20)  ==>  (3, 30)
pairMap2 : (a -> a -> a) -> (a, a) -> (a, a) -> (a, a)
pairMap2 f (x1, y1) (x2, y2) = (f x1 x2, f y1 y2)
    
-- 抽象構文木(AST)への再帰的処理のひな形
-- 以下の処理を葉から根にかけてボトムアップに適用する
-- - 葉には初期値を与える関数uを適用
-- - 葉以外のノードには以下の4引数の関数fを適用
-- f(d,n,b,r)の各引数の意味：
-- d: 各ブロック間の間隔
-- n: 葉以外の各ノード
-- b: サブAST bに対する処理済みの結果
-- r: サブAST rに対する処理済みの結果
-- 使用例： 
-- recurAST 0 (\_ a b c -> a + b + c) (\_ -> 0) (0,0) (AST 1 (AST 2 Nil Nil) (AST 3 Nil Nil)) 
-- ==> 6 (= 1 + 2 + 3)
recurAST : Magnitude -> 
           (Position -> a -> acc -> acc -> acc) -> 
           (Position -> acc) ->
           Position -> AST a -> acc
recurAST d f u (x, y) ast = 
    case ast of
        Nil -> 
            u (x, y)
        AST node bottom right ->     
            f (x, y)
              node
              (recurAST d f u (x, y + d) bottom)
              (recurAST d f u (x + d, y) right)

--ASTxyからASTneを取得する
getASTne : ASTxy Node -> ASTne Node
getASTne astxy =
         case astxy of
             ASTxy _ (ASTne node astb astr) ->
                 ASTne node astb astr
                 
--ASTneからNodeを取得する
getASTneNode : ASTne Node -> Node
getASTneNode astne =
            case astne of
                ASTne node _ _ ->
                    node
                    
-- モデルに（根の位置情報付きの）ASTを追加
addASTxy : ASTxy Node -> Model -> Model
addASTxy astxy model = 
        { model | getASTRoots = model.getASTRoots ++ [astxy] }

-- モデルから（根の位置情報付きの）ASTを削除
-- elmは参照透明なので等価性の判定は参照同値ではなく構造同値であることに注意
-- 実際は根の位置情報の食い違いで非等価がすぐに分かるのでAST全体を調べることはまれ
removeAST : ASTxy Node -> Model -> Model
removeAST astxy model =
    { model | getASTRoots = 
                model.getASTRoots |> List.filter (\a -> a /= astxy) 
    }    

-- サブASTの複製を追加
-- 純粋関数型言語であるElmではあらゆるデータは不変（persistent）なので
-- 実際にはASTの複製をつくる必要がないことに注意
-- 単にクリックしたマウスの座標情報を付加した上で元のサブASTを共有するだけ
-- でよいので非常に効率的で軽い処理 
cloneUs : ASTne Node -> Mouse.Event -> Model -> Model
cloneUs (ASTne n b r) event model =
    if event.button == Mouse.MainButton || model.getDnDInfo.getOnDnD || (n.getBrickCommand == CommandNOP) then
        model
    else
        addASTxy (ASTxy (pairMap2 (+) 
                          (pairMap2 (-) event.pagePos event.offsetPos) --凹凸を含む左上の角の座標
                          (10, 10)) -- 元のブロックと完全に重ならないように少しずらす
                        (ASTne n b r))
                 model    

-- ASTの移動
-- 単に根の位置情報を変更するだけでよいので非常に軽い処理
moveUs : Mouse.Event -> Model -> Model
moveUs event model = 
    if not model.getDnDInfo.getOnDnD then 
        -- MsgAttachMeの直後にMsgMoveUsが生じてブリックが不作為にリープするバグへの対処
        -- おそらくメッセージがキューされていて，タイミングが悪いとDnD終了後であっても
        -- MsgAttachMeが生じるものと思われる．
        model
    else    
        { model | getDnDInfo =
            { getOnDnD = model.getDnDInfo.getOnDnD
            , getXY0 = model.getDnDInfo.getXY0
            , getBrickXY = model.getDnDInfo.getBrickXY
            , getMoveXY = pairMap2 (-) event.clientPos model.getDnDInfo.getXY0
            }
        }

insideBrick : Position -> Position -> Bool
insideBrick (x0, y0) (x, y) = 
    y0 - mergin <= y && y <= y0 + mergin &&
    x0 - mergin <= x && x <= x0 + mergin 

-- ドラッグアンドドロップ（DnD）の開始をモデルに記録
startDnD : Mouse.Event -> (Model, Position) -> Model
startDnD event (model, xy) = 
    if event.button /= Mouse.MainButton  then
        model
    else     
        { model | getDnDInfo = { getOnDnD = True
                               , getXY0 = pairMap2 (-) event.clientPos xy --event.offsetPos
                               , getBrickXY = xy
                               , getMoveXY = xy --pairMap2 (-) event.clientPos  event.offsetPos
                               } }

-- 根専用のDnD開始処理
--再表示をすることによってブロック群を最前面に表示させる
startDnDxy : ASTxy Node -> Mouse.Event -> Model -> Model
startDnDxy (ASTxy xy (ASTne node bottom right)) event model = 
    if event.button /= Mouse.MainButton  then
        model
    else     
        { model | getDnDInfo = { getOnDnD = True
                               , getXY0 = pairMap2 (-) event.clientPos xy --event.offsetPos
                               , getBrickXY = xy
                               , getMoveXY = xy --pairMap2 (-) event.clientPos  event.offsetPos
                               } }
        |> removeAST (ASTxy xy (ASTne node bottom right))
        |> addASTxy (ASTxy xy (ASTne node bottom right))   

-- ドラッグアンドドロップ（DnD）の終了をモデルに記録
stopDnD : Mouse.Event -> Model -> Model
stopDnD event model =
    if event.button /= Mouse.MainButton  then
        model
    else   
        -- getXY0 = (0, 0)は不要だが，デバッガで見やすいように0をセット
        { model | getDnDInfo = { getOnDnD = False, getXY0 = (0, 0), getBrickXY = (0, 0), getMoveXY = (0, 0) } }

-- マウスでクリックした位置のブロックを根とするASTをモデルに追加する
-- 元のASTがすべて作り直される重い処理
-- 順序木への挿入処理のように本当は根に至る最小限の経路のみ作り直したいが，
-- クリック位置情報だけからはどちらの部分木の配下が更新されるのか判定できない
-- のでやむを得ない
letMeRoot : ASTne Node -> Mouse.Event -> Model -> (Model, Position)
letMeRoot (ASTne node bottom right) event model = 
    if event.button /= Mouse.MainButton || model.getDnDInfo.getOnDnD 
    then
        (model, pairMap2 (-) event.pagePos event.offsetPos)
    else     
        let
            -- 新規のルートポジション
            xy =  pairMap2 (-) event.pagePos event.offsetPos
                
            f xy0 n b r =
                if insideBrick xy0 xy then 
                    Nil -- 部分ASTをNilで置換
                else
                    AST n b r -- すべてのノードを作り直し
        in
            ({ model | getASTRoots = 
                model.getASTRoots 
                |> List.map (\(ASTxy (x, y) (ASTne n b r)) ->
                        let d = interval model 
                        in ASTxy (x, y)
                            (ASTne n
                                (recurAST d f (\_ -> Nil) (x, y + d) b)
                                (recurAST d f (\_ -> Nil) (x + d, y) r)
                            )
                    )
            }                                        
            |> addASTxy (ASTxy xy (ASTne node bottom right)) 
            , xy)

--追加、recurASTを変更。rescurASTはletMeRootにも使われているためattachMe専用のrescurASTを作成
recurAttachAST : Magnitude -> 
           (Position -> Node -> W (AST Node) -> W (AST Node) -> W (AST Node)) -> 
           (Position -> W (AST Node)) ->
           Position -> AST Node -> W (AST Node)
recurAttachAST d f u (x, y) ast = 
    case ast of
        Nil -> 
            u (x, y)
        AST node bottom right ->
            if node.getBrickType /= TailBrick then --変更、探索途中にTailBrickがあるかどうかを判定
            f (x, y)
              node
              (recurAttachAST d f u (x, y + d) bottom)
              (recurAttachAST d f u (x + d, y) right)
              else  unit (AST node bottom right)--変更、探索途中にTailがあった場合何も変更を加えない処理を行う
              
-- ASTを別のASTの葉に接木する
-- かならずしも接木が行われるとは限らない（近接ブロックがない位置でマウスをリリースするかもしれない）
-- よって接木が成功したことを確認した上ではじめてAST astをASTのリストから削除すべきことに注意
-- letMeRootと同様，すべてのASTを作り直すことになる重い処理（接木したい位置情報からだけでは
-- どちらの部分木配下が対象になるのか判定しようがないので致し方ない）
attachMe : ASTxy Node -> Position -> Mouse.Event -> Model -> Model
attachMe (ASTxy xy (ASTne node bottom right)) xy1 event model = 
  if event.button /= Mouse.MainButton || not model.getDnDInfo.getOnDnD then model
  else
    let 
        model1 = removeAST (ASTxy xy1 (ASTne node bottom right)) model
        -- 接続できたときのみastをルートリストから削除するために
        -- Writerアプリカティブで変更の有無を判定
        u xy0 = 
          if insideBrick xy0 xy then 
                (AST node bottom right, Changed)
          else
                unit Nil

        f _ n b r =
            unit (AST n) |> andMap b |> andMap r
    in    
        if node.getBrickType == EntryBrick then
            rePos (ASTxy xy (ASTne node bottom right)) model1
        else
            let 
                (newRoots, isChanged) = 
                 listMapW  
                     (
                         (\(ASTxy (x, y) (ASTne n b r)) ->
                         if n.getBrickType /= TailBrick then --追加、根のBrickTypeがTailで無いことを判定する
                             let d = interval model1
                             in 
                                unit (\ab ar -> ASTxy (x, y) (ASTne n ab ar))
                                |> andMap (recurAttachAST d f u (x, y + d) b) 
                                |> andMap (recurAttachAST d f u (x + d, y) r)
                              else unit (ASTxy (x, y) (ASTne n b r)) --追加、根のBrickTypeがTailの場合何も変更を加えない処理を行う
                         )
                      )
                      model1.getASTRoots
                newModel = 
                    { model1 | getASTRoots = newRoots }
            in
                -- 接木が成功したことを確認したときだけリストから削除する
                if isChanged == Changed then
                    newModel |> removeAST (ASTxy xy (ASTne node bottom right))
                else
                    rePos (ASTxy xy (ASTne node bottom right)) newModel

-- ブロックの座標確認用関数
-- 座標の照合のために、let式で対象のブロック情報を一度削除する
rePos : ASTxy Node -> Model -> Model
rePos (ASTxy xy (ASTne node bottom right)) model =
    if not model.getDnDInfo.getOnDnD then model
    else
        let model2 = removeAST (ASTxy xy (ASTne node bottom right)) model
        in  addASTxy (ASTxy (fixPos xy (List.map pickPos model2.getASTRoots)) (ASTne node bottom right)) model2

-- ブロック情報から座標のみ取り出す関数
pickPos : ASTxy Node -> Position
pickPos (ASTxy xy (ASTne node bottom right)) = xy

-- ブロック座標の照合の処理をする関数
-- 対象ブロックと座標が近いブロックが存在する場合は遠ざかる
fixPos : Position -> List Position -> Position
fixPos (x, y) listxy =
    let
        xy : List Position
        xy = List.repeat (List.length listxy) (x, y)
        
        fixResult : Bool
        fixResult = List.member True (List.map2 comparePos xy listxy)
    in
        if fixResult then fixPos (x + mergin, y + mergin) listxy
        else (x, y)

-- ブロック照合判定用関数
-- insideBrickと全く同じ処理
comparePos : Position -> Position -> Bool
comparePos (x0, y0) (x, y) = 
    y0 - mergin <= y && y <= y0 + mergin &&
    x0 - mergin <= x && x <= x0 + mergin 

-- 入力した引数の格納
-- この関数では根の座標を参照し、対象の構文木を検索する
inputValuexy : Position -> String -> String -> Model -> Model
inputValuexy xy argCode value model =
    { model | getASTRoots = 
        model.getASTRoots 
        |> List.map(\(ASTxy p (ASTne n b r)) -> 
            if p == xy then
                if String.isEmpty argCode then
                    ASTxy p (ASTne {n | getBrickArgument = {disp = n.getBrickArgument.disp, value = value} } b r)
                else
                    ASTxy p (ASTne n (inputValue argCode "b" value b) (inputValue argCode "r" value r))
            else
                ASTxy p (ASTne n b r)
        )
    }

-- 入力した引数の格納
-- この関数では葉の座標を参照し、対象のブロックに文字列を格納する
inputValue : String -> String -> String -> AST Node -> AST Node
inputValue argCode checkCode value ast =
    case ast of
        Nil ->
            Nil
        AST n b r ->
            if argCode == checkCode then
                AST { n | getBrickArgument = {disp = n.getBrickArgument.disp, value = value} } b r
            else
                AST n (inputValue argCode (checkCode ++ "b") value b) (inputValue argCode (checkCode ++ "r") value r)


-- VIEW

view : Model -> Html Msg
view model =
    div [ style "position" "relative"
        , style "height" "930px"
        , style "top" "0px"
        , style "left" "0px"
        , style "background" "#eee"
        --, on "mousemove" (\event -> MsgMoveUs event)
        ]
        [
          model.getASTRoots
          |> List.indexedMap (\index astxy -> (String.fromInt index, viewASTxy model astxy)) 
          |> Keyed.node "div" []
        ]

-- 根のブロックの描画
viewASTxy : Model -> ASTxy Node -> Html Msg
viewASTxy model (ASTxy (x1, y1) (ASTne n b r)) = 
    let
      (x, y) = if (x1,y1) == model.getDnDInfo.getBrickXY then model.getDnDInfo.getMoveXY
               else (x1,y1)
    in
    Keyed.node "div"
    [ style "position" "absolute"
    , style "top"  (String.fromFloat y ++ "px")
    , style "left" (String.fromFloat x ++ "px")
    -- MsgLetMeRootは部分木に対してしか意味をなさないのでここで根にはセットしない
    -- 代わりにmousedownに対してはMsgStartDnDを単独でセット
    --, on "mousemove" (\event -> MsgMoveUs (x, y) event)
    --, on "mouseup"   (\event -> MsgAttachMe (ASTxy (x, y) (ASTne n b r)) (x1,y1) event)
    --, on "contextmenu" (\event -> MsgCloneUs (ASTne n b r) event)
    --, on "mousedown" (\event -> MsgStartDnD (ASTxy (x, y) (ASTne n b r)) event) 
    , on "click" (\event -> SendCommand event n.getBrickCommand)
    ] 
    [ --("N", brickSvg model.getBrickSize)　変更箇所
    ("N", case n.getBrickType of
                    BasicBrick ->
                        basicBrickSvg model.getBrickSize n.getBrickCommand n.getBrickArgument "" (x,y)
                    EntryBrick ->
                        entryBrickSvg model.getBrickSize n.getBrickCommand n.getBrickArgument "" (x,y)
                    TailBrick ->
                        tailBrickSvg model.getBrickSize n.getBrickCommand n.getBrickArgument "" (x,y)
                    CaseBrick ->
                        caseBrickSvg model.getBrickSize n.getBrickCommand n.getBrickArgument "" (x,y)
        ) -- 実際のブロックの描画はbrickSvgで
    , ("R", lazy5 viewAST model.getBrickSize True  r "r" (x,y))
    , ("B", lazy5 viewAST model.getBrickSize False b "b" (x,y))
    ]  

-- 根以外の描画
viewAST: Magnitude -> Bool -> AST Node -> String -> Position -> Html Msg
viewAST size isRight ast argCode xy = 
    case ast of
        Nil ->
            div [] [] 
        AST node b r ->
            Keyed.node "div"
                [ style "position" "absolute"
                , style "top"  <| (if isRight then "0" else String.fromFloat (size * 0.9)) ++ "px"
                , style "left" <| (if isRight then String.fromFloat (size * 0.9) else "0") ++ "px"
                --, on "contextmenu" (\event -> MsgCloneUs   (ASTne node b r) event)
                --, on "mousedown"   (\event -> MsgLetMeRoot (ASTne node b r) xy event)
                --, stopPropagationOn "mousemove" (Json.succeed (Dummy,True))
                --, stopPropagationOn "mouseup" (Json.succeed (Dummy,True))
                , on "click" (\event -> SendCommand event node.getBrickCommand)
                ]
                [ --("N", brickSvg size) 変更箇所
                ("N", case node.getBrickType of
                            BasicBrick ->
                                basicBrickSvg size node.getBrickCommand node.getBrickArgument argCode xy
                            EntryBrick ->
                                entryBrickSvg size node.getBrickCommand node.getBrickArgument argCode xy
                            TailBrick ->
                                tailBrickSvg size node.getBrickCommand node.getBrickArgument argCode xy
                            CaseBrick ->
                                caseBrickSvg size node.getBrickCommand node.getBrickArgument argCode xy
                ) -- 実際のブロックの描画はbrickSvgで
                , ("R", lazy5 viewAST size True  r (argCode ++ "r") xy)
                , ("B", lazy5 viewAST size False b (argCode ++ "b") xy)
                ]                        

-- ブリック要素は入れ子の木になっているので伝搬を止めないと複数のブリックが
-- イベントを複数ひろってしまうことに注意
on : String -> (Mouse.Event -> msg) -> Html.Attribute msg
on eventName =
    { stopPropagation = True, preventDefault = if eventName == "contextmenu" || eventName == "mousemove" then True else False }
        |> Mouse.onWithOptions eventName

-- 実際に各々のブロックを描く関数
basicBrickSvg : Float ->  BrickCommand -> Argument -> String -> Position -> Html Msg
basicBrickSvg size command argument argCode xy = div [] 
  [ Svg.svg 
    [ width  <| String.fromFloat size
    , height <| String.fromFloat size 
    , viewBox "166 70 336 336"
    ]
    [ Svg.path
        [ d "M 500 220.06632 L 500 110 C 500 104.47715 495.52285 100 490 100 L 379.9337 100 C 379.46895 93.00195 376.5621 86.13573 371.2132 80.78682 C 359.49746 69.07104 340.50254 69.07104 328.78682 80.78682 C 323.4379 86.13573 320.53105 93.00195 320.0663 100 L 320.0663 100 L 210 100 C 204.47715 100 200 104.47715 200 110 L 200 220.06632 C 191.6702 219.51314 183.15363 222.41997 176.78682 228.78682 C 165.07104 240.50254 165.07104 259.49746 176.78682 271.21318 C 183.15363 277.58003 191.6702 280.48686 200 279.9337 L 200 390 C 200 395.52285 204.47715 400 210 400 L 320.0663 400 C 320.53105 393.00195 323.4379 386.13573 328.78682 380.7868 C 340.50254 369.07104 359.49746 369.07104 371.2132 380.7868 C 376.5621 386.13573 379.46895 393.00195 379.9337 400 L 490 400 C 495.52285 400 500 395.52285 500 390 L 500 279.9337 C 491.6702 280.48686 483.15363 277.58003 476.7868 271.21318 C 465.07104 259.49746 465.07104 240.50254 476.7868 228.78682 C 483.15363 222.41997 491.6702 219.51314 500 220.06632 Z"
        , stroke "gray"
        , fill "yellow"
        , strokeWidth "6"
        ] []
    , Svg.svg [x "166", y"70", viewBox "0 0 135 50"] [
        Svg.text_ [x "15" , y "0" , fill "black"] [Svg.text (viewCommand command)]
      , Svg.text_ [x "20" , y "25", fill "black"] [Svg.text (argument.disp)]
      ]
    ]
  , if not (String.isEmpty argument.disp) then
      input [ placeholder "引数"
            , Html.Attributes.style "position" "absolute"
            , Html.Attributes.style "top" "50px"
            , Html.Attributes.style "left" "50px"
            , Html.Attributes.style "width" "40px"
            , value argument.value
            , on "mouseup" (\event -> Dummy event) --stopPropagationOn "mouseup" (Json.succeed (Dummy,True))
            , on "mousedown" (\event -> Dummy event) --stopPropagationOn "mousedown" (Json.succeed (Dummy,True))
            , stopPropagationOn "input" <| Json.map alwaysStop (Json.map (MsgInputChanged xy argCode) targetValue)
            ] []
    else div [] []
  ]

alwaysStop : a -> (a, Bool)
alwaysStop x =
    (x, True)

entryBrickSvg size command argument argCode xy = div []
  [ Svg.svg 
    [ width  <| String.fromFloat size
    , height <| String.fromFloat size 
    , viewBox "166 70 336 336"
    ]
    [ Svg.path
        [ d "M 500 220.06632 L 500 110 C 500 104.47715 495.52285 100 490 100 L 379.9337 100  L 320.0663 100 L 210 100 C 204.47715 100 200 104.47715 200 110 L 200 220.06632  L 200 390 C 200 395.52285 204.47715 400 210 400 L 320.0663 400 C 320.53105 393.00195 323.4379 386.13573 328.78682 380.7868 C 340.50254 369.07104 359.49746 369.07104 371.2132 380.7868 C 376.5621 386.13573 379.46895 393.00195 379.9337 400 L 490 400 C 495.52285 400 500 395.52285 500 390 L 500 279.9337 C 491.6702 280.48686 483.15363 277.58003 476.7868 271.21318 C 465.07104 259.49746 465.07104 240.50254 476.7868 228.78682 C 483.15363 222.41997 491.6702 219.51314 500 220.06632 Z"
        , stroke "gray"
        , fill "skyblue"
        , strokeWidth "6"
        ] []
    , Svg.svg [x "166", y"70", viewBox "0 0 135 50"]
      [Svg.text_ [x "15" , y "0" , fill "black"] [Svg.text (viewCommand command)]
      , Svg.text_ [x "20" , y "25", fill "black"] [Svg.text (argument.disp)]
      ]
    ]
  , if not (String.isEmpty argument.disp) then
      input [ placeholder "引数"
          , Html.Attributes.style "position" "absolute"
          , Html.Attributes.style "top" "50px"
          , Html.Attributes.style "left" "50px"
          , Html.Attributes.style "width" "40px"
          , value argument.value
          , on "mouseup" (\event -> Dummy event) --stopPropagationOn "mouseup" (Json.succeed (Dummy,True))
          , on "mousedown" (\event -> Dummy event) --stopPropagationOn "mousedown" (Json.succeed (Dummy,True))
          , stopPropagationOn "input" <| Json.map alwaysStop (Json.map (MsgInputChanged xy argCode) targetValue)
          ] []
    else div [] []
  ]

tailBrickSvg size command argument argCode xy = div []
  [ Svg.svg 
    [ width  <| String.fromFloat size
    , height <| String.fromFloat size 
    , viewBox "166 70 336 336"
    ]
    [ Svg.path
        [ d "M 500 220.06632 L 500 110 C 500 104.47715 495.52285 100 490 100 L 379.9337 100 C 379.46895 93.00195 376.5621 86.13573 371.2132 80.78682 C 359.49746 69.07104 340.50254 69.07104 328.78682 80.78682 C 323.4379 86.13573 320.53105 93.00195 320.0663 100 L 320.0663 100 L 210 100 C 204.47715 100 200 104.47715 200 110 L 200 220.06632 C 191.6702 219.51314 183.15363 222.41997 176.78682 228.78682 C 165.07104 240.50254 165.07104 259.49746 176.78682 271.21318 C 183.15363 277.58003 191.6702 280.48686 200 279.9337 L 200 390 C 200 395.52285 204.47715 400 210 400 L 320.0663 400 L 490 400 C 495.52285 400 500 395.52285 500 390 L 500 279.9337 Z"
        , stroke "gray"
        , fill "pink"
        , strokeWidth "6"
        ] []
    , Svg.svg [x "166", y"70", viewBox "0 0 135 50"]
      [Svg.text_ [x "15" , y "0" , fill "black"] [Svg.text (viewCommand command)]
      , Svg.text_ [x "20" , y "25", fill "black"] [Svg.text (argument.disp)]
      ]
    ]
  , if not (String.isEmpty argument.disp) then
      input [ placeholder "引数"
          , Html.Attributes.style "position" "absolute"
          , Html.Attributes.style "top" "50px"
          , Html.Attributes.style "left" "50px"
          , Html.Attributes.style "width" "40px"
          , value argument.value
          , on "mouseup" (\event -> Dummy event) --stopPropagationOn "mouseup" (Json.succeed (Dummy,True))
          , on "mousedown" (\event -> Dummy event) --stopPropagationOn "mousedown" (Json.succeed (Dummy,True))
          , stopPropagationOn "input" <| Json.map alwaysStop (Json.map (MsgInputChanged xy argCode) targetValue)
          ] []
    else div [] []
  ] 
    
caseBrickSvg size command argument argCode xy = div []
  [ Svg.svg 
   [ width  <| String.fromFloat size
    , height <| String.fromFloat size 
    , viewBox "166 70 336 336"
    ]
    [ Svg.path
        [ d "M 500 220.06632 L 500 110 C 500 104.47715 495.52285 100 490 100 L 379.9337 100 C 379.46895 93.00195 376.5621 86.13573 371.2132 80.78682 C 359.49746 69.07104 340.50254 69.07104 328.78682 80.78682 C 323.4379 86.13573 320.53105 93.00195 320.0663 100 L 320.0663 100 L 210 100 C 204.47715 100 200 104.47715 200 110 L 200 220.06632 C 191.6702 219.51314 183.15363 222.41997 176.78682 228.78682 C 165.07104 240.50254 165.07104 259.49746 176.78682 271.21318 C 183.15363 277.58003 191.6702 280.48686 200 279.9337 L 200 390 C 200 395.52285 204.47715 400 210 400 L 320.0663 400 C 320.53105 393.00195 323.4379 386.13573 328.78682 380.7868 C 340.50254 369.07104 359.49746 369.07104 371.2132 380.7868 C 376.5621 386.13573 379.46895 393.00195 379.9337 400 L 490 400 C 495.52285 400 500 395.52285 500 390 L 500 279.9337 C 491.6702 280.48686 483.15363 277.58003 476.7868 271.21318 C 465.07104 259.49746 465.07104 240.50254 476.7868 228.78682 C 483.15363 222.41997 491.6702 219.51314 500 220.06632 Z"
        , stroke "gray"
        , fill "limegreen"
        , strokeWidth "6"
        ] []
    , Svg.svg [x "166", y"70", viewBox "0 0 135 50"]
      [Svg.text_ [x "15" , y "0" , fill "black"] [Svg.text (viewCommand command)]
      , Svg.text_ [x "20" , y "25", fill "black"] [Svg.text (argument.disp)]
      ]
    ]
  , if not (String.isEmpty argument.disp) then
      input [ placeholder "引数"
          , Html.Attributes.style "position" "absolute"
          , Html.Attributes.style "top" "50px"
          , Html.Attributes.style "left" "50px"
          , Html.Attributes.style "width" "40px"
          , value argument.value
          , on "mouseup" (\event -> Dummy event) --stopPropagationOn "mouseup" (Json.succeed (Dummy,True))
          , on "mousedown" (\event -> Dummy event) --stopPropagationOn "mousedown" (Json.succeed (Dummy,True))
          , stopPropagationOn "input" <| Json.map alwaysStop (Json.map (MsgInputChanged xy argCode) targetValue)
          ] []
    else div [] []
  ] 


viewCommand : BrickCommand -> String
viewCommand command =
    case command of
      CommandNOP -> "動作開始"
      CommandMove -> "前進する"
      CommandTurnRight -> "右を向く"
      CommandTurnLeft -> "左を向く"
      CommandTurnBack -> "後ろを向く"
      --CommandTurnSet -> "向きをn度にする"
      --CommandResetXY -> "座標(0,0)に移動"
      --CommandSetX -> "xをnにする"
      --CommandChangeX -> "xをnずつ変える"
      --CommandSetY -> "yをnにする"
      --CommandChangeY -> "yをnずつ変える"
      --CommandDownPen -> "ペンを下げる"
      --CommandUpPen -> "ペンを上げる"
      CommandFuncStart -> "関数nを開始"
      CommandFuncStop -> "関数nへ移動"
      --CommandIf -> "if制御"
      CommandIfS -> "前に進めるなら"
      CommandIfR -> "右に進めるなら"
      CommandIfL -> "左に進めるなら"
      CommandIfB -> "後ろ進めるなら"
      CommandNone -> "なにもしない"
      CommandReboot -> "繰り返し動作"
      _ -> "error"


subscriptions : Model -> Sub Msg
subscriptions model = Sub.none
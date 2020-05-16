port module Main exposing (main)

import Browser
import File exposing (File)
import Html exposing (..)
import Html.Attributes as Attributes
import Html.Events as Events
import Json.Decode as Decode exposing (Decoder, Value)



-- MODEL


type alias Model =
    List ( File, String )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ input
            [ Attributes.type_ "file"
            , Events.on "change" (Decode.map FileSelected filesDecoder)
            ]
            []
        , case model of
            [] ->
                text ""

            files ->
                ul [] (List.map viewFile files)
        ]


viewFile : ( File, String ) -> Html msg
viewFile ( file, md5 ) =
    li []
        [ text (File.name file)
        , br [] []
        , text md5
        ]



-- PORTS


port gotFile : (Value -> msg) -> Sub msg


port sendFile : Value -> Cmd msg



-- DECODERS


filesDecoder : Decoder (List Value)
filesDecoder =
    Decode.at [ "target", "files" ] (Decode.list Decode.value)


decodeFile : Decoder ( File, String )
decodeFile =
    Decode.map2 Tuple.pair
        (Decode.at [ "file" ] File.decoder)
        (Decode.at [ "hash" ] Decode.string)



-- UPDATE


type Msg
    = FileSelected (List Value)
    | FileReceived (Result Decode.Error ( File, String ))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FileSelected [] ->
            ( model, Cmd.none )

        FileSelected (file :: _) ->
            ( model, sendFile file )

        FileReceived (Ok ( file, md5 )) ->
            ( ( file, md5 ) :: model, Cmd.none )

        FileReceived (Err _) ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    gotFile (Decode.decodeValue decodeFile >> FileReceived)



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = always ( [], Cmd.none )
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

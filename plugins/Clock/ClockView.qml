import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../../core"
import "../../services"
import "../../widgets"

FadeIn {
    id: view

    property var tray: null
    property var juego: null

    //  Lo que mide de verdad CADA zona, para que el plugin sepa cuánto tiene
    //  que reservar. Se mide aquí porque es aquí donde están los widgets con su
    //  fuente puesta: cuánto ocupa «🔔 claude · k4» no se sabe contando
    //  constantes, y contándolas era como se sabía —de ahí que las píldoras de
    //  los agentes acabaran pintadas encima de la hora—.
    //
    //  Las tres y no solo la derecha: con las zonas encadenadas, lo que mida la
    //  fecha corre el reloj, y lo que mida el reloj corre los indicadores.
    readonly property int anchoIzquierdo: grupoIzq.implicitWidth
    readonly property int anchoCentro: reloj.implicitWidth
    readonly property int anchoDerecho: grupoDer.implicitWidth

    //  El aire entre una zona y la siguiente. El plugin reparte con este mismo
    //  número, así que si cambia, cambia en los dos sitios o la cuenta deja de
    //  cuadrar y vuelve el solape.
    readonly property int hueco: 24

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        anchors.topMargin: 0
        anchors.bottomMargin: Notifs.recent.length > 0 ? 12 : 0
        spacing: 6

        //  Tres zonas ENCADENADAS, igual que en la píldora plegada: cada una
        //  empieza donde acaba la anterior, y esa es toda la regla.
        //
        //  Estaban ancladas a su borde —fecha a la izquierda, hora al centro de
        //  la caja, indicadores a la derecha—, y eso obliga a que lo reservado
        //  cuadre AL PÍXEL con lo que mide de verdad. No cuadraba: el plugin
        //  acotaba el flanco derecho para que la island no se comiera la
        //  pantalla, y al pasarse de ese tope la fila crecía hacia dentro desde
        //  el borde derecho y acababa pintada encima de la hora. Es exactamente
        //  el fallo que ya se arregló en la píldora, y la misma cura: colgadas
        //  unas de otras, el solape no es que no pase, es que no cabe. Lo que no
        //  quepa se sale por la derecha y lo recorta la island, que es lo menos
        //  malo de las dos cosas.
        //
        //  El precio es el mismo que allí: la hora deja de estar en el centro
        //  exacto de la caja y queda donde la dejen la fecha y su aire. A cambio
        //  cada píxel de indicador vale uno y no dos, así que ahora cabe casi el
        //  doble de flanco derecho antes de tocar el tope.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 68

            ColumnLayout {
                id: grupoIzq
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                IslandLabel {
                    text: Clock.date.toLocaleDateString(Idioma.locale, "dddd")
                    color: Theme.muted
                    font.pixelSize: 11
                    font.capitalization: Font.Capitalize
                }

                IslandLabel {
                    text: Clock.date.toLocaleDateString(Idioma.locale, "d MMMM")
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }
            }

            IslandLabel {
                id: reloj

                //  Colgada de la fecha, no al centro de la caja: la caja ya no
                //  reserva lo mismo a los dos lados, así que su centro no es
                //  donde va la hora.
                anchors.left: grupoIzq.right
                anchors.leftMargin: view.hueco
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(Clock.date, "HH:mm")
                font.pixelSize: 30
                font.weight: Font.Light
            }

            RowLayout {
                id: grupoDer

                //  Y los indicadores colgados de la HORA, cerrando la cadena.
                anchors.left: reloj.right
                anchors.leftMargin: view.hueco
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Minimizados {
                    interactive: true
                    Layout.alignment: Qt.AlignVCenter
                }

                GrabacionPildora {
                    interactive: true
                    Layout.alignment: Qt.AlignVCenter
                    onParar: Captura.parar()
                }

                JuegoPildora {
                    interactive: true
                    Layout.alignment: Qt.AlignVCenter
                    onAbrir: if (view.juego) view.juego.toggle()
                }

                PluginPildora {
                    interactive: true
                    Layout.alignment: Qt.AlignVCenter
                }

                // La island ya está desplegada y quieta: aquí sí se pincha.
                TrayRow {
                    max: 5
                    iconSize: 16
                    interactive: true
                    Layout.alignment: Qt.AlignVCenter
                    onMenuRequested: if (view.tray) view.tray.toggle()
                }

                // Battery indicator — rightmost item in the hover view.
                RowLayout {
                    id: bateriaPildora
                    spacing: 5
                    Layout.alignment: Qt.AlignVCenter

                    readonly property var dispositivo: UPower.displayDevice

                    readonly property int porcentaje: {
                        if (!dispositivo || !dispositivo.ready)
                            return -1

                        const raw = Number(dispositivo.percentage)
                        if (!isFinite(raw))
                            return -1

                        return Math.max(0, Math.min(100,
                            Math.round(raw <= 1 ? raw * 100 : raw)))
                    }

                    readonly property bool cargando: dispositivo
                        && (dispositivo.state === UPowerDeviceState.Charging
                            || dispositivo.state === UPowerDeviceState.PendingCharge)

                    readonly property color tinta: cargando ? Theme.green
                        : porcentaje <= 15 ? Theme.red
                        : porcentaje <= 30 ? Theme.yellow
                        : Theme.muted

                    visible: dispositivo && dispositivo.ready && porcentaje >= 0

                    IconGlyph {
                        text: {
                            if (bateriaPildora.cargando)
                                return String.fromCodePoint(0xF0084)

                            const p = bateriaPildora.porcentaje
                            if (p <= 5) return String.fromCodePoint(0xF0083)
                            if (p <= 10) return String.fromCodePoint(0xF007A)
                            if (p <= 20) return String.fromCodePoint(0xF007B)
                            if (p <= 30) return String.fromCodePoint(0xF007C)
                            if (p <= 40) return String.fromCodePoint(0xF007D)
                            if (p <= 50) return String.fromCodePoint(0xF007E)
                            if (p <= 60) return String.fromCodePoint(0xF007F)
                            if (p <= 70) return String.fromCodePoint(0xF0080)
                            if (p <= 80) return String.fromCodePoint(0xF0081)
                            if (p <= 90) return String.fromCodePoint(0xF0082)

                            return String.fromCodePoint(0xF0079)
                        }

                        color: bateriaPildora.tinta
                        font.pixelSize: 14
                        Layout.alignment: Qt.AlignVCenter
                    }

                    IslandLabel {
                        text: bateriaPildora.porcentaje + "%"
                        color: bateriaPildora.tinta
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }

        // Lo que acaba de llegar, sin tener que abrir el panel.
        NotifStrip {
            max: 3
            Layout.fillWidth: true
        }
    }
}

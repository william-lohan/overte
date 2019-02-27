//
//  MicBar.qml
//  qml/hifi/audio
//
//  Created by Zach Pomerantz on 6/14/2017
//  Copyright 2017 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

import QtQuick 2.5
import QtGraphicalEffects 1.0
import stylesUit 1.0

import stylesUit 1.0
import TabletScriptingInterface 1.0

Rectangle {
    HifiConstants { id: hifi; }

    readonly property var level: AudioScriptingInterface.inputLevel;
    readonly property var clipping: AudioScriptingInterface.clipping;
    readonly property var muted: AudioScriptingInterface.muted;
    readonly property var pushToTalk: AudioScriptingInterface.pushToTalk;
    readonly property var pushingToTalk: AudioScriptingInterface.pushingToTalk;

    readonly property var userSpeakingLevel: 0.4;
    property bool gated: false;
    Component.onCompleted: {
        AudioScriptingInterface.noiseGateOpened.connect(function() { gated = false; });
        AudioScriptingInterface.noiseGateClosed.connect(function() { gated = true; });
    }

    property bool standalone: false;
    property var dragTarget: null;

    width: 44;
    height: 44;

    radius: 5;

    color: "#00000000";
    border {
        width: mouseArea.containsMouse || mouseArea.containsPress ? 2 : 0;
        color: colors.border;
    }

    // borders are painted over fill, so reduce the fill to fit inside the border
    Rectangle {
        color: standalone ? colors.fill : "#00000000";
        width: 40;
        height: 40;

        radius: 5;

        anchors {
            verticalCenter: parent.verticalCenter;
            horizontalCenter: parent.horizontalCenter;
        }
    }

    MouseArea {
        id: mouseArea;

        anchors {
            left: icon.left;
            right: bar.right;
            top: icon.top;
            bottom: icon.bottom;
        }

        hoverEnabled: true;
        scrollGestureEnabled: false;
        onClicked: {
            if (AudioScriptingInterface.pushToTalk) {
                return;
            }
            muted = !muted;
            Tablet.playSound(TabletEnums.ButtonClick);
        }
        drag.target: dragTarget;
        onContainsMouseChanged: {
            if (containsMouse) {
                Tablet.playSound(TabletEnums.ButtonHover);
            }
        }
    }

    QtObject {
        id: colors;

        readonly property string unmuted: "#FFF";
        readonly property string muted: "#E2334D";
        readonly property string gutter: "#575757";
        readonly property string greenStart: "#39A38F";
        readonly property string greenEnd: "#1FC6A6";
        readonly property string yellow: "#C0C000";
        readonly property string red: colors.muted;
        readonly property string fill: "#55000000";
        readonly property string border: standalone ? "#80FFFFFF" : "#55FFFFFF";
        readonly property string icon: muted ? muted : unmuted;
    }

    Item {
        id: icon;

        anchors {
            left: parent.left;
            verticalCenter: parent.verticalCenter;
        }

        width: 40;
        height: 40;

        Item {
            Image {
                readonly property string unmutedIcon: "../../../icons/tablet-icons/mic-unmute-i.svg";
                readonly property string mutedIcon: "../../../icons/tablet-icons/mic-mute-i.svg";
                readonly property string pushToTalkIcon: "../../../icons/tablet-icons/mic-ptt-i.svg";
                readonly property string clippingIcon: "../../../icons/tablet-icons/mic-clip-i.svg";
                readonly property string gatedIcon: "../../../icons/tablet-icons/mic-gate-i.svg";

                id: image;
                source: (pushToTalk && !pushingToTalk) ? pushToTalkIcon : muted ? mutedIcon : 
                    clipping ? clippingIcon : gated ? gatedIcon : unmutedIcon;

                width: 21;
                height: 24;
                anchors {
                    left: parent.left;
                    leftMargin: 7;
                    top: parent.top;
                    topMargin: 5;
                }
            }

            ColorOverlay {
                anchors { fill: image }
                source: image;
                color: colors.icon;
            }
        }
    }

    Item {
        id: status;

        readonly property string color: colors.muted;

        visible: (pushToTalk && !pushingToTalk) || (muted && (level >= userSpeakingLevel));

        anchors {
            left: parent.left;
            top: parent.bottom
            topMargin: 5
        }

        width: icon.width;
        height: 8

        RalewaySemiBold {
            anchors {
                horizontalCenter: parent.horizontalCenter;
                verticalCenter: parent.verticalCenter;
            }

            color: parent.color;

            text: (pushToTalk && !pushingToTalk) ? (HMD.active ? "MUTED PTT" : "MUTED PTT-(T)") : (muted ? "MUTED" : "MUTE");
            font.pointSize: 12;
        }

        Rectangle {
            anchors {
                left: parent.left;
                verticalCenter: parent.verticalCenter;
            }

            width: AudioScriptingInterface.pushToTalk && !AudioScriptingInterface.pushingToTalk ? (HMD.active ? 27 : 25) : 50;
            height: 4;
            color: parent.color;
        }

        Rectangle {
            anchors {
                right: parent.right;
                verticalCenter: parent.verticalCenter;
            }

            width: AudioScriptingInterface.pushToTalk && !AudioScriptingInterface.pushingToTalk ? (HMD.active ? 27 : 25) : 50;
            height: 4;
            color: parent.color;
        }
    }

    Item {
        id: bar;

        anchors {
            right: parent.right;
            rightMargin: 7;
            verticalCenter: parent.verticalCenter;
        }

        width: 8;
        height: 32;

        Rectangle { // base
            radius: 4;
            anchors { fill: parent }
            color: colors.gutter;
        }

        Rectangle { // mask
            id: mask;
            height: parent.height * level;
            width: parent.width;
            radius: 5;
            anchors {
                bottom: parent.bottom;
                bottomMargin: 0;
                left: parent.left;
                leftMargin: 0;
            }
        }

        LinearGradient {
            anchors { fill: mask }
            source: mask
            start: Qt.point(0, 0);
            end: Qt.point(0, bar.height);
            rotation: 180
            gradient: Gradient {
                GradientStop {
                    position: 0.0;
                    color: colors.greenStart;
                }
                GradientStop {
                    position: 0.5;
                    color: colors.greenEnd;
                }
                GradientStop {
                    position: 1.0;
                    color: colors.red;
                }
            }
        }

        Rectangle {
            id: gatedIndicator;
            visible: gated && !AudioScriptingInterface.clipping

            radius: 4;
            width: 2 * radius;
            height: 2 * radius;
            color: "#0080FF";
            anchors {
                right: parent.left;
                verticalCenter: parent.verticalCenter;
            }
        }

        Rectangle {
            id: clippingIndicator;
            visible: AudioScriptingInterface.clipping

            radius: 4;
            width: 2 * radius;
            height: 2 * radius;
            color: colors.red;
            anchors {
                left: parent.right;
                verticalCenter: parent.verticalCenter;
            }
        }
    }
}

/*
 * \copyright Copyright (c) 2016-2020 Governikus GmbH & Co. KG, Germany
 */

import QtQuick 2.10

import Governikus.Global 1.0
import Governikus.Style 1.0
import Governikus.Type.SettingsModel 1.0


Item {
	id: baseItem

	height: button.height + Constants.component_spacing
	width: parent.width

	property string selectedCategory: ""
	property string providerIcon: ""
	property string address: ""
	property color titleBarColor

	Rectangle {
		id: iconContainer

		height: 2 * baseItem.height
		width: height

		anchors.left: parent.left
		anchors.leftMargin: Constants.component_spacing
		anchors.verticalCenter: baseItem.top

		radius: Style.dimens.corner_radius
		color: Constants.white
		border.color: Style.color.border
		border.width: Style.dimens.separator_size

		Image {
			id: icon

			anchors.fill: parent
			anchors.margins: iconContainer.radius / 2

			source: baseItem.providerIcon
			asynchronous: true
			fillMode: Image.PreserveAspectFit
		}
	}

	GButton {
		id: button

		anchors.left: iconContainer.right
		anchors.leftMargin: Constants.component_spacing
		anchors.bottom: iconContainer.bottom

		//: LABEL ANDROID_TABLET IOS_TABLET
		text: qsTr("To provider") + SettingsModel.translationTrigger
		tintIcon: true
		icon.source: "qrc:///images/link_external.svg"
		buttonColor: baseItem.titleBarColor
		enabled: baseItem.address !== ""

		onClicked: {
			if (baseItem.address !== "") {
				Qt.openUrlExternally(baseItem.address)
			}
		}
	}
}

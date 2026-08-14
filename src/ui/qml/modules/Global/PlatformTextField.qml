/**
 * Copyright (c) 2017-2026 Governikus GmbH & Co. KG, Germany
 */

import QtQuick
import QtQuick.Controls

import Governikus.Type

BasePlatformTextField {
	id: root

	ToolTip.text: d.maxReachedText
	ToolTip.visible: !ApplicationModel.screenReaderRunning && d.maxReached(root.text)

	// iOS prioritizes manual announcements and kills previous ones like the content announcement
	onActiveFocusChanged: Qt.platform.os !== "ios" && root.activeFocus && d.announceMaxReached()
	onTextChanged: d.announceMaxReached()

	QtObject {
		id: d

		//: ALL_PLATFORMS
		readonly property string maxReachedText: qsTr("Maximum allowed length reached.")

		function announceMaxReached() {
			if (ApplicationModel.screenReaderRunning && d.maxReached(root.text))
				root.Accessible.announce(d.maxReachedText);
		}
		function maxReached(pText) {
			return pText.length === root.maximumLength;
		}
	}
}

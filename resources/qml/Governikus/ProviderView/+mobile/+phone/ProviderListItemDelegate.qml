/*
 * \copyright Copyright (c) 2019-2020 Governikus GmbH & Co. KG, Germany
 */

import QtQuick 2.10
import QtGraphicalEffects 1.0

import Governikus.Global 1.0
import Governikus.Type.SettingsModel 1.0
import Governikus.Type.ProviderCategoryFilterModel 1.0


ListItem {
	property string sectionName

	Accessible.description: qsTr("Open provider details for") + ' ' + display + SettingsModel.translationTrigger

	text: display

	onClicked: firePushWithProperties(providerDetailView, {providerModelItem: model})
}

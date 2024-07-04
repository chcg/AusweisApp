/**
 * Copyright (c) 2020-2024 Governikus GmbH & Co. KG, Germany
 */

/*!
 * \brief Model implementation for checking the ID card in "playground".
 */

#pragma once

#include "ReaderInfo.h"

#include <QObject>
#include <QtQml/qqmlregistration.h>


namespace governikus
{

class CheckIDCardModel
	: public QObject
{
	Q_OBJECT
	Q_CLASSINFO("RegisterEnumClassesUnscoped", "false")
	Q_PROPERTY(Result result READ getResult NOTIFY fireResultChanged)
	QML_ELEMENT

	public:
		enum class Result
		{
			UNKNOWN,
			NO_NFC,
			CARD_NOT_DETECTED,
			UNKNOWN_CARD_DETECTED,
			ID_CARD_DETECTED,
			INSUFFICIENT_APDU_LENGTH,
			CARD_ACCESS_FAILED,
			PIN_DEACTIVATED,
			PIN_SUSPENDED,
			PIN_BLOCKED,
			SUCCESS
		};
		Q_ENUM(Result)

		explicit CheckIDCardModel(QObject* pParent = nullptr);
		~CheckIDCardModel() override;

		Q_INVOKABLE void startScan();
		Q_INVOKABLE void startScanIfNecessary();
		Q_INVOKABLE void stopScan();

		[[nodiscard]] Result getResult() const;

	private:
		bool mIsRunning;
		Result mResult;
		QString mReaderWithCard;

	private Q_SLOTS:
		void onCardInserted(const ReaderInfo& pInfo);
		void onCardRemoved(const ReaderInfo& pInfo);
		void onReaderAdded(const ReaderInfo& pInfo);
		void onReaderRemoved(const ReaderInfo& pInfo);
		void onReaderPropertiesUpdated(const ReaderInfo& pInfo);

		void stopScanWithResult(Result result);

	Q_SIGNALS:
		void fireResultChanged();
		void fireScanCompleted();
};

} // namespace governikus

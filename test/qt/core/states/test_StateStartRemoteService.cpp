/*!
 * \copyright Copyright (c) 2018-2019 Governikus GmbH & Co. KG, Germany
 */

#include "states/remote_service/StateStartRemoteService.h"

#include "MockCardConnectionWorker.h"
#include "MockRemoteServer.h"
#include "states/StateBuilder.h"

#include <QtTest>


using namespace governikus;

class test_StateStartRemoteService
	: public QObject
{
	Q_OBJECT

	private Q_SLOTS:
		void initTestCase()
		{
			Env::setCreator<RemoteServer*>(std::function<RemoteServer*()>([&] {
						return new MockRemoteServer();
					}));
		}


		void test_Run()
		{
			const QSharedPointer<RemoteServiceContext> context(new RemoteServiceContext());
			const QSharedPointer<StateStartRemoteService> state(StateBuilder::createState<StateStartRemoteService>(context));
			QSignalSpy spyContinue(state.data(), &StateStartRemoteService::fireContinue);

			state->onEntry(nullptr);
			context->setStateApproved();
			QCOMPARE(spyContinue.count(), 1);

			const auto& server = context->getRemoteServer();
			const QSharedPointer<ServerMessageHandler> handler(new ServerMessageHandlerImpl(nullptr));
			Q_EMIT server->fireMessageHandlerAdded(handler);
			Q_EMIT handler->fireClosed();
			QCOMPARE(context->getNewPin(), QString());
			QCOMPARE(context->getPin(), QString());
			QCOMPARE(context->getCan(), QString());
			QCOMPARE(context->getPuk(), QString());
			QCOMPARE(context->getCardConnection(), QSharedPointer<CardConnection>());
			QCOMPARE(context->getLastPaceResult(), CardReturnCode::OK);
			QCOMPARE(context->getEstablishPaceChannelMessage(), QSharedPointer<const IfdEstablishPaceChannel>());
			QCOMPARE(context->getModifyPinMessage(), QSharedPointer<const IfdModifyPin>());
		}


};

QTEST_GUILESS_MAIN(test_StateStartRemoteService)
#include "test_StateStartRemoteService.moc"
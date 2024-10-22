import common.Review

def j = new Review
	(
		name: 'iOS_Simulator_arm64_Framework',
		libraries: 'iOS_Simulator_arm64',
		label: 'iOS',
		artifacts: 'build/*.zip,build/*.bcsymbolmap'
	).generate(this)


j.with
{
	steps
	{
		shell('cmake -P source/ci.cmake')
	}
}

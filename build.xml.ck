<?xml version="1.0" encoding="UTF-8"?>
<project name="php-automate-build-ant" default="full-build">

    <!-- By default the tools are managed by Composer in ${basedir}/vendor/bin -->
    <property name="pdepend" value="${basedir}/vendor/bin/pdepend"/>
    <property name="phpcpd" value="${basedir}/vendor/bin/phpcpd"/>
    <property name="phpcs" value="${basedir}/vendor/bin/phpcs"/>
    <property name="phpdox" value="${basedir}/vendor/bin/phpdox"/>
    <property name="phploc" value="${basedir}/vendor/bin/phploc"/>
    <property name="phpmd" value="${basedir}/vendor/bin/phpmd"/>
    <property name="phpunit" value="${basedir}/vendor/bin/phpunit"/>

    <target name="clean" unless="clean.done" description="Cleanup build artifacts.">
        <delete dir="${basedir}/build/api"/>
        <delete dir="${basedir}/build/coverage"/>
        <delete dir="${basedir}/build/logs"/>
        <delete dir="${basedir}/build/pdepend"/>
        <delete dir="${basedir}/build/phpdox"/>
        <property name="clean.done" value="true"/>
    </target>

    <target name="composer" description="Install composer packages including require-dev.">
        <get src="https://getcomposer.org/download/1.2.1/composer.phar" dest="composer.phar"/>
        <exec executable="php" failonerror="true">
            <arg value="${basedir}/composer.phar"/>
            <arg value="install"/>
            <arg value="--prefer-dist"/>
            <arg value="--no-progress"/>
        </exec>
    </target>

    <target name="full-build" depends="prepare,composer,static-analysis,phpunit,phpdox,-check-failure"
            description="Perform static analysis, run tests, and generate project documentation.">
        <echo message="Built"/>
    </target>

    <target name="lint" unless="lint.done" description="Perform syntax check of PHP sourcecode files.">
        <apply executable="php" failonerror="true" taskname="lint">
            <arg value="-l"/>
            <fileset dir="${basedir}/src">
                <include name="**/*.php"/>
                <!-- modified/ -->
            </fileset>
            <fileset dir="${basedir}/tests">
                <include name="**/*.php"/>
                <!-- modified/ -->
            </fileset>
        </apply>
        <property name="lint.done" value="true"/>
    </target>

    <target name="pdepend" unless="pdepend.done" depends="prepare"
            description="Calculate software metrics using PHP_Depend and log result in XML format. Intended for usage within a continuous integration environment.">
        <exec executable="${pdepend}" taskname="pdepend">
            <arg value="--jdepend-xml=${basedir}/build/logs/jdepend.xml"/>
            <arg value="--jdepend-chart=${basedir}/build/pdepend/dependencies.svg"/>
            <arg value="--overview-pyramid=${basedir}/build/pdepend/overview-pyramid.svg"/>
            <arg path="${basedir}/src"/>
        </exec>
        <property name="pdepend.done" value="true"/>
    </target>

    <target name="phpcpd" unless="phpcpd.done"
            description="Find duplicate code using PHPCPD and print human readable output. Intended for usage on the command line before committing.">
        <exec executable="${phpcpd}" taskname="phpcpd">
            <arg path="${basedir}/src"/>
        </exec>
        <property name="phpcpd.done" value="true"/>
    </target>

    <target name="phpcpd-ci" unless="phpcpd.done" depends="prepare"
            description="Find duplicate code using PHPCPD and log result in XML format. Intended for usage within a continuous integration environment.">
        <exec executable="${phpcpd}" taskname="phpcpd">
            <arg value="--log-pmd"/>
            <arg path="${basedir}/build/logs/pmd-cpd.xml"/>
            <arg path="${basedir}/src"/>
        </exec>
        <property name="phpcpd.done" value="true"/>
    </target>

    <target name="phpcs" unless="phpcs.done"
            description="Find coding standard violations using PHP_CodeSniffer and print human readable output. Intended for usage on the command line before committing.">
        <exec executable="${phpcs}" taskname="phpcs">
            <arg value="--standard=PSR2"/>
            <arg value="--extensions=php"/>
            <arg value="--ignore=autoload.php"/>
            <arg path="${basedir}/src"/>
            <arg path="${basedir}/tests"/>
        </exec>
        <property name="phpcs.done" value="true"/>
    </target>

    <target name="phpcs-ci" unless="phpcs.done" depends="prepare"
            description="Find coding standard violations using PHP_CodeSniffer and log result in XML format. Intended for usage within a continuous integration environment.">
        <exec executable="${phpcs}" output="/dev/null" taskname="phpcs">
            <arg value="--report=checkstyle"/>
            <arg value="--report-file=${basedir}/build/logs/checkstyle.xml"/>
            <arg value="--standard=PSR2"/>
            <arg value="--extensions=php"/>
            <arg value="--ignore=autoload.php"/>
            <arg path="${basedir}/src"/>
            <arg path="${basedir}/tests"/>
        </exec>
        <property name="phpcs.done" value="true"/>
    </target>

    <target name="phpdox" unless="phpdox.done" depends="phploc-ci,phpcs-ci,phpmd-ci"
            description="Generate project documentation using phpDox.">
        <exec executable="${phpdox}" dir="${basedir}/build" taskname="phpdox"/>
        <property name="phpdox.done" value="true"/>
    </target>

    <target name="phploc" unless="phploc.done"
            description="Measure project size using PHPLOC and print human readable output. Intended for usage on the command line.">
        <exec executable="${phploc}" taskname="phploc">
            <arg value="--count-tests"/>
            <arg path="${basedir}/src"/>
            <arg path="${basedir}/tests"/>
        </exec>
        <property name="phploc.done" value="true"/>
    </target>

    <target name="phploc-ci" unless="phploc.done" depends="prepare"
            description="Measure project size using PHPLOC and log result in CSV and XML format. Intended for usage within a continuous integration environment.">
        <exec executable="${phploc}" taskname="phploc">
            <arg value="--count-tests"/>
            <arg value="--log-csv"/>
            <arg path="${basedir}/build/logs/phploc.csv"/>
            <arg value="--log-xml"/>
            <arg path="${basedir}/build/logs/phploc.xml"/>
            <arg path="${basedir}/src"/>
            <arg path="${basedir}/tests"/>
        </exec>
        <property name="phploc.done" value="true"/>
    </target>

    <target name="phpmd" unless="phpmd.done"
            description="Perform project mess detection using PHPMD and print human readable output. Intended for usage on the command line before committing.">
        <exec executable="${phpmd}" taskname="phpmd">
            <arg path="${basedir}/src"/>
            <arg value="text"/>
            <arg path="${basedir}/build/phpmd.xml"/>
        </exec>
        <property name="phpmd.done" value="true"/>
    </target>

    <target name="phpmd-ci" unless="phpmd.done" depends="prepare"
            description="Perform project mess detection using PHPMD and log result in XML format. Intended for usage within a continuous integration environment.">
        <exec executable="${phpmd}" taskname="phpmd">
            <arg path="${basedir}/src"/>
            <arg value="xml"/>
            <arg path="${basedir}/build/phpmd.xml"/>
            <arg value="--reportfile"/>
            <arg path="${basedir}/build/logs/pmd.xml"/>
        </exec>
        <property name="phpmd.done" value="true"/>
    </target>

    <target name="phpunit" unless="phpunit.done" depends="prepare" description="Run unit tests with PHPUnit.">
        <exec executable="${phpunit}" resultproperty="result.phpunit" taskname="phpunit">
            <arg value="--configuration"/>
            <arg path="${basedir}/build/phpunit.xml"/>
            <arg path="tests"/>
        </exec>
        <property name="phpunit.done" value="true"/>
    </target>

    <target name="phpunit-no-coverage" unless="phpunit.done" depends="prepare"
            description="Run unit tests with PHPUnit without generating code coverage reports.">
        <exec executable="${phpunit}" failonerror="true" taskname="phpunit">
            <arg value="--configuration"/>
            <arg path="${basedir}/build/phpunit.xml"/>
            <arg path="tests"/>
            <arg value="--no-coverage"/>
        </exec>
        <property name="phpunit.done" value="true"/>
    </target>

    <target name="prepare" unless="prepare.done" depends="clean" description="Prepare for build.">
        <mkdir dir="${basedir}/build/api"/>
        <mkdir dir="${basedir}/build/coverage"/>
        <mkdir dir="${basedir}/build/logs"/>
        <mkdir dir="${basedir}/build/pdepend"/>
        <mkdir dir="${basedir}/build/phpdox"/>
        <property name="prepare.done" value="true"/>
    </target>

    <target name="quick-build" depends="prepare,composer,lint,phpunit-no-coverage"
            description="Perform lint check and run tests without generating code coverage reports.">
        <echo message="Built"/>
    </target>

    <target name="static-analysis" depends="lint,phploc-ci,pdepend,phpmd-ci,phpcs-ci,phpcpd-ci"
            description="Perform static analysis.">
        <echo message="Done"/>
    </target>

    <target name="-check-failure">
        <fail message="PHPUnit did not finish successfully">
            <condition>
                <not>
                    <equals arg1="${result.phpunit}" arg2="0"/>
                </not>
            </condition>
        </fail>
        <echo message="Checked failure"/>
    </target>

</project>

--
-- Database: `pyrothorn_testing`
--

-- --------------------------------------------------------

--
-- Table structure for table `queries`
--

CREATE TABLE IF NOT EXISTS `queries` (
  `queryid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `queryrunID` text NOT NULL,
  `query_hash` text NOT NULL,
  `query_count` int(10) unsigned NOT NULL,
  `query_timestamp` varchar(120) NOT NULL,
  `query` text NOT NULL,
  `direct_sql_rows` int(11) NOT NULL,
  `firethorn_sql_rows` int(11) NOT NULL,
  `firethorn_duration` varchar(60) NOT NULL,
  `sql_duration` varchar(60) NOT NULL,
  `test_passed` tinyint(1) NOT NULL,
  `firethorn_version` varchar(60) NOT NULL,
  `firethorn_error_message` text NOT NULL,
  `sql_error_message` text NOT NULL,
  `java_version` varchar(120) NOT NULL,
  `sys_timestamp` varchar(60) NOT NULL,
  `firethorn_changeset` varchar(60) NOT NULL,
  `sys_platform` varchar(60) NOT NULL,
  PRIMARY KEY (`queryid`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

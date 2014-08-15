#!/bin/bash
pub global deactivate bwu_testrunner
pub global activate bwu_testrunner '>=0.1.0 <0.2.0'
pub global run bwu_testrunner:run -i

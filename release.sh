#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2017-2022 2017 Martynas Jusevicius, <martynas@atomgraph.com> et al.
#
# SPDX-License-Identifier: Apache-2.0

mvn release:clean release:prepare

mvn release:perform
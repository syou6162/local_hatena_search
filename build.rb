# -*- coding: utf-8 -*-
require "builder"

Builder.new(YAML.load_file("config.yaml")).build

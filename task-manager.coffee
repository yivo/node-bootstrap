# Define application root directory
path = require 'path'
GLOBAL.rootDirectory = path.dirname(process.mainModule.filename)

OutputMediator  = require 'yivo-node-log'
Exception       = require 'yivo-node-exception'
registry        = require 'yivo-node-registry'
_               = require 'lodash'

taskName = process.argv[2]
task = null
taskScript = null

# Lookup task function
['coffee', 'js'].forEach (ext) ->
  return if _.isFunction task
  try
    taskScript = rootDirectory + "/tasks/#{taskName}.#{ext}"
    task = require taskScript
  catch e

# Oops
throw "Task '#{taskName}' not found in '#{rootDirectory}/tasks'" unless _.isFunction task

# Options
options = (option.replace /^-*([^-]*)-*$/, '$1' for option in process.argv.slice(3))
disableOutput = 'no-output' in options
runAsync = 'async' in options
numberOfErrors = 0
errorsThreshold = 25

OutputMediator.disable() if disableOutput

log = OutputMediator.create('task-manager')
log.ok "Root directory is '#{rootDirectory}'"
log.ok "Task resolved with '#{taskScript}'"

taskCompleteHandler = ->
  log.ok "Task '#{taskName}' completed!"
  process.exit()

taskErrorHandler = (err) ->
  return unless err
  log.print 'err', err.sender, err.toString()
  saveError err
  if ++numberOfErrors > errorsThreshold
    log.err('Too many errors. Exiting') and process.exit(-1)
  else
    setTimeout taskWrapper, 0

saveError = (err) ->
  # do save error

if runAsync
  taskWrapper = ->
    try
      task()
      taskCompleteHandler()
    catch err 
      taskErrorHandler(err)
else
  Sync = require 'sync'
  taskWrapper = ->
    Sync ->
      task()
      taskCompleteHandler()
    , taskErrorHandler

taskWrapper()

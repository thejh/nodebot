http = require 'http-get'

jsonget = (url, cb) ->
  http.get {url}, (err, res) ->
    return cb err if err
    try
      json = JSON.parse res.buffer.toString()
    catch er
      return cb er
    cb null, json

POLL_INTERVAL = 60000
# API keys are application specific, not person specific. This is intentional.
KEY = "iwhPd5DZUEeQVwQxeZTO9g"
APIURL = "http://api.stackoverflow.com/1.1/"

module.exports = class StackOverflow
  constructor: (@sendLine) ->
    jsonget "#{APIURL}questions?pagesize=1&tagged=node.js&key=#{KEY}", (err, json) =>
      throw err if err?
      if !json.questions || !json.questions[0] || !json.questions[0].creation_date || !json.questions[0].question_id
        throw new Error 'not 1 question in expected format back'
      @_lastQuestionsDate = json.questions[0].creation_date
      @_lastQuestionId = json.questions[0].question_id
      @_scheudleNextRequest()
  
  _scheudleNextRequest: ->
    setTimeout =>
      url = "#{APIURL}questions?pagesize=100&fromdate=#{@_lastQuestionsDate}&tagged=node.js&key=#{KEY}"
      jsonget url, (err, json) =>
        return console.error err if err
        json.questions.filter (question) =>
          if question.creation_date > @_lastQuestionsDate
            @_lastQuestionsDate = question.creation_date
          if question.question_id > @_lastQuestionId
            @_lastQuestionId = question.question_id
          question.question_id > @_lastQuestionId
        .forEach (question) =>
          @sendLine "http://stackoverflow.com/questions/#{question.question_id} #{question.title}"
        @_scheudleNextRequest()
    , POLL_INTERVAL

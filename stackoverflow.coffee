gzipBuffer = require 'gzip-buffer'
request = require 'request'

jsonget = (url, cb) ->
  request {uri: url, encoding: null}, (err, res, zippedBody) ->
    return cb err if err
    gzipBuffer.gunzip zippedBody, (body) ->
      return cb (new Error 'invalid gzipped data') if not body
      body = body.toString 'utf8'
      try
        json = JSON.parse body
      catch er
        console.error "'#{body}'"
        return cb er
      cb null, json

POLL_INTERVAL = 60000
# API keys are application specific, not person specific. This is intentional.
KEY = "iwhPd5DZUEeQVwQxeZTO9g"
APIURL = "http://api.stackoverflow.com/1.1/"

module.exports = class StackOverflow
  constructor: (@tag, @sendLine) ->
    jsonget "#{APIURL}questions?pagesize=1&tagged=#{@tag}&key=#{KEY}", (err, json) =>
      throw err if err?
      if !json.questions || !json.questions[0] || !json.questions[0].creation_date || !json.questions[0].question_id
        throw new Error 'not 1 question in expected format back'
      @_lastQuestionsDate = json.questions[0].creation_date
      @_lastQuestionId = json.questions[0].question_id
      @_scheudleNextRequest()
  
  _scheudleNextRequest: ->
    setTimeout =>
      url = "#{APIURL}questions?pagesize=100&fromdate=#{@_lastQuestionsDate}&tagged=#{@tag}&key=#{KEY}"
      jsonget url, (err, json) =>
        return console.error err if err
        json.questions.filter (question) =>
          result = question.question_id > @_lastQuestionId
          if question.creation_date > @_lastQuestionsDate
            @_lastQuestionsDate = question.creation_date
          if question.question_id > @_lastQuestionId
            @_lastQuestionId = question.question_id
          result
        .forEach (question) =>
          tags = question.tags or []
          if (tags.indexOf @tag) > -1
            tags.splice (tags.indexOf @tag), 1
          tags =
            if tags.length is 0
              ""
            else
              " (tags: #{tags.join ', '})"
          link = "http://stackoverflow.com/q/#{question.question_id}"
          @sendLine "'#{question.title}' by #{question.owner?.display_name} #{link}#{tags}"
        @_scheudleNextRequest()
    , POLL_INTERVAL

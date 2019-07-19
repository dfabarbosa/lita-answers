require 'lita'

module Lita
  module Handlers
    class Answers < Handler
      TEXT = /[\w\s\,\.\-\/:–]+/
      QUESTION = /(?:'|")(#{TEXT.source}\?)(?:'|")/
      ANSWER = /(?:'|")(#{TEXT.source}\.?)(?:'|")/
      QUESTION2 = /(#{TEXT.source}\?)/


      route(/^(\w+)([\.#]|::)?(\w+)?$/, :documentation, command: false, help: {
        "Array#map" => "# Array#map\n\n(from ruby core)\n---\n    ary.collect { |item| block }  -> new_ary\n..."
      })

      route(/^all\smemes$/i, :index, command: true, help: {
        "all memes" => "You could ask me the following questions: 1) ... 2) ..."
      })

      route(/^remember\s#{QUESTION.source}\swith\s#{ANSWER.source}$/i, :create, command: true, help: {
        "remember 'meme' with 'link or phrase'" => "The response for 'meme' is 'link or phrase'."
      })

      route(/^answer\s#{QUESTION2.source}$/i, :show, command: true, help: {
        "meme 'meme'" => "link."
      })

      route(/^change\s#{QUESTION.source}\sto\s#{ANSWER.source}$/i, :update, command: true, help: {
        "change 'meme' to 'link or phrase'" => "The new response for 'meme' is 'link or phrase'."
      })

      route(/^forget\s#{QUESTION2.source}$/i, :destroy, command: true, help: {
        "forget 'meme'" => "Forgot 'meme'"
      })

      def documentation(response)
        question = response.matches.join
        reply = RubyDocs::Documentation.search(question)
        response.reply(reply)
      end

      def index(response)
        questions = Knowledgebase.all
        if questions.any?
          reply = "You could ask me for the following memes:"
          questions.map.with_index do |question, index|
            reply << "\n#{index+1}) #{question}"
          end
        else
          reply = "There are no memes yet! " \
                  "Use REMEMBER 'meme' WITH 'link or phrase' syntax for creating memes.\n" \
                  "For more info see: help remember."
        end
        response.reply(reply)
      end

      def create(response)
        question, answer = response.matches.first
        if Knowledgebase.exists?(question)
          answer = Knowledgebase.read(question)
          reply = "Use CHANGE 'meme' TO 'link or phrase' syntax for existing memes! " \
                  "For more info see: help change.\n" \
                  "The response for '#{question}' is still '#{answer}'"
        else
          Knowledgebase.create(question, answer)
          reply = "The response for '#{question}' is '#{answer}'"
        end
        response.reply(reply)
      end

      def show(response)
        question = response.matches.first[0]
        reply = Knowledgebase.read(question) || begin
          closest_question = Nlp.closest_sentence(question, Knowledgebase.all)
          if closest_question.nil?
            no_such_question
          else
            "Found the closest meme to your query: '#{closest_question}'. " \
            "Use REMEMBER 'meme' WITH 'link or phrase' syntax for creating memes.\n" \
            "For more info see: help remember."
          end
        end
        response.reply(reply)
      end

      def update(response)
        question, new_answer = response.matches.first
        if Knowledgebase.exists?(question)
          Knowledgebase.update(question, new_answer)
          reply = "The new response for '#{question}' is '#{new_answer}'."
        else
          reply = no_such_question
        end
        response.reply(reply)
      end

      def destroy(response)
        question = response.matches.first[0]
        if Knowledgebase.exists?(question)
          Knowledgebase.destroy(question)
          reply = "Forgot '#{question}'"
        else
          reply = no_such_question
        end
        response.reply(reply)
      end

      private

        def no_such_question
          'There is no such a meme! Use ALL MEMES command.'
        end
    end

    Lita.register_handler(Answers)
  end
end

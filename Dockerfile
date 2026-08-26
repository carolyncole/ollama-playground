FROM ruby:4.0

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN gpg; true
# command to install firefox are from https://support.mozilla.org/en-US/kb/install-firefox-linux
RUN install -d -m 0755 /etc/apt/keyrings
RUN wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
RUN gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") print "\nThe key fingerprint matches ("$0").\n"; else print "\nVerification failed: the fingerprint ("$0") does not match the expected one.\n"}'
RUN echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
COPY docker-files/mozilla.sources /etc/apt/sources.list.d/mozilla.sources
COPY docker-files/mozilla.prefs /etc/apt/preferences.d/mozilla
RUN apt-get update && apt-get install firefox -y
RUN apt-get install npm -y
RUN bundle config frozen false

WORKDIR /usr/src/app

RUN gem install hanami
COPY rails_bookshelf ./rails_bookshelf
WORKDIR /usr/src/app/rails_bookshelf

RUN bundle install
RUN bin/rails db:migrate
EXPOSE 3000
EXPOSE 2300
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

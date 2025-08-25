A small Ruby CLI tool to fetch all songs by a given artist

## Setup

1. **Clone the repository**

```bash
git clone https://github.com/meesterdude/genius_test
cd genius_test
````

2. **Install dependencies**

```bash
bundle install
```

3. **Set environment variables**

Create a `.env` file in the project root with your Genius API token:

```env
GENIUS_ACCESS_TOKEN=your_genius_api_access_token
```

## Usage

Run the CLI to fetch *ALL* songs by an artist (may take a while):

```bash
bin/songs "Queen"
```

Optionally, you can limit the number of result pages fetched:

```bash
bin/songs "Queen" 3
```

Output:

```
=== Songs for Queen ===
Bohemian Rhapsody
Another One Bites the Dust
...
```

## Testing

This project uses **Minitest** and **WebMock** for tests.

Run all tests:

```bash
bundle exec rake
```

### Notes

* Real HTTP requests are stubbed in tests, so no API calls are made during testing.
* Handles timeouts and API errors for Genius API
* Allows other providers to be created and utilized, as long as they implement an #artist_songs method. 


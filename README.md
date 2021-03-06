# SWSheets

SWSheets is a simple application for creating, storing, sharing, and printing Edge of the Empire characters online. It is not intended to enforce any rules of character building or provide any aids beyond calculating die rolls. It used to be called EdgeBuiler until I couldn't get that domain. I'm not going to rename that in the code anytime soon though.

## Planned Features & Suggestions

Please use the [issues page](https://github.com/citizenparker/swsheets/issues)

## Setup

SWSheets was built against Elixir 1.0.2, Erlang 17.3, and PostgreSQL 9.3. Once you have all three installed, do the following to set up the app:

```
> mix deps.get
```

Once Mix has fetched all dependencies, you'll need to set up the database. An easy way to do this for local development follows (this approach is not recommended for production).

```
> createuser pair -d
> script/dbdo
```

## Running

To run SWSheets, type `mix phoenix.server`.

Now you can visit `localhost:4000` from your browser.

## Deploying

I use [ansible-swsheets](https://github.com/citizenparker/ansible-swsheets). You could probably use Heroku too though.

## Testing
If you have run `script/dbdo` then you're ready to test with
```
> mix test
```

## License

All work within this repo is released under a [Creative Commons Attribution-NonCommercial 3.0 United States](https://creativecommons.org/licenses/by-nc/3.0/us/) license. Essentially you are welcome to do what you like with this as long as you provide attribution and don't charge for it.

Star Wars, Edge of the Empire, and all associated works remain the copyright of their respective copyright holders.

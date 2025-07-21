---
layout: post
title: Where Does Apple Hide Your Voice Memo Transcripts?
subtitle: How I discovered the transcripts Apple buries inside .m4a audio files
date: '2025-06-08'
tags: ["ruby","reverse-engineering"]
---

Much like having thoughts in the shower and working on trains, I often find my best thinking happens while walking my dog in the morning. To not lose track of all this good thinking, I've started recording voice notes on my iPhone using Apple's _Voice Memos_ app.

After recording, the app automatically generates transcriptions, allowing me to easily search, copy, and edit my memos. Unfortunately—Apple being Apple—you can't access these transcripts from anywhere outside the Voice Memos app.

---

Just want to see the code? Check out these Gists:

<div class="grid">

  <a href="https://gist.github.com/thomascountz/b84b68f0a7c6f2f851ebc5db152b676a" target="_blank" rel="noopener noreferrer" class="button" style="text-align: center;text-decoration:none;">
    Ruby
  </a>

  <a href="https://gist.github.com/thomascountz/287d7dd1e04674d22a6396433937cd29" target="_blank" rel="noopener noreferrer" class="button" style="text-align: center;text-decoration:none;">
    Bash
  </a>
</div>

---

Using _Voice Memos_ ticks a lot of boxes for me:

1. **I can be a better dog dad**: I used to bring a small notebook on our morning walks, but I felt rude asking my dog to wait while I scribbled something every few meters.
2. **I get to think out loud**: I've found that verbalizing my ideas helps me organize, prioritize, and clarify them.
3. **I actually use my notes**: Writing emails, drafting blog posts, making todo lists; automatic transcriptions are queryable and ready for editing.

This is what's called a "win-win-win"—and I love it when it happens—but that last "win" doesn't come as easily as the others.

## Step 0: The Problem

Unfortunately, the only way to get your transcripts out of _Voice Memos_ and into somewhere useful, is to clumsily copy-and-paste them.

This is an example of the worst kind of problem.

Copying-and-pasting isn't a big deal, I know. But it is _just enough of a deal_ to stop me from using the transcripts like I want to—which have become more valuable to me than the audio itself.

Plus, if there's anything we programmers hate most, it's copying-and-pasting... isn't that what we have computers for?

## Step 1: Find the Transcripts

Thinking of how I might solve this, I was reminded of a time when I tried exporting text from _Apple Notes_. When synced via iCloud, I learned that _Notes_ uses SQLite and that it was accessible on Mac.

```bash
~/Library/Group Containers/group.com.apple.notes/NoteStore.sqlite
```

Thankfully, the authors of tools like [apple-notes-to-sqlite](https://github.com/dogsheep/apple-notes-to-sqlite) had already deciphered and documented the complicated schemas and built open source tools to solve my problem.

I dove in hoping the same would be true for _Voice Memos_.

However, in the far reaches of Apple StackExchange, I came across this:

> Q. Where are the transcripts that are generated from recordings in the Voice Memos app stored in the file system?
>
> A. There is no documentation from Apple that I know of, but the MPEG-4 standard provides for encoding a text stream in the container itself; i.e., the *.m4a file. That must be what Voice Memos is doing. I don't see any separate file resulting from transciption [sic]. See: ISO/IEC 14496-17:2006(en) Information technology — Coding of audio-visual objects — Part 17: Streaming text format (iso.org)
>
> — [_Location of Voice Memos transcripts in the file system?_, Apple StackExchange](https://apple.stackexchange.com/questions/478073/location-of-voice-memos-transcripts-in-the-file-system)

The good news was that, when synced via iCloud, the _Voice Memos_ audio could be accessed as `.m4a` files directly.

```bash
~/Library/Group Containers/group.com.apple.VoiceMemos.shared/Recordings/
```

The bad news was that I didn't know anything about audio file formats or what "...encoding a text stream in the container itself..." meant.

## Step 2: Explore the Files

To postpone having to open up any part of ISO/IEC 14496[^14496-12], I thought I'd just poke around the `.m4a` files a bit.

[^14496-12]: The ISO/IEC 14496 standard is a huge standard with multiple parts. _Part 12_ defines the ISO Base Media File Format, which is the core of many media file formats, including `.mp4` and `.m4a`. _Part 17_, which the StackExchange answer mentions, defines the Streaming Text Format, which is used for text streams in media files.

If you try opening one of those files in a text editor, you'll see that it is not meant to be read by humans. But, useful plaintext strings can often be found buried within various binary formats.

Finding these hidden strings is something reverse engineers do when they otherwise don't know how to decompile or deconstruct a binary file. (`.m4a` is a well established format, but we haven't read the documentation yet, remember?)

If Apple is encoding transcripts directly within the `.m4a` file, as the StackExchange answer suggested, we might be able to see them using the command line tool, [`strings`](https://manpages.ubuntu.com/manpages/questing/en/man1/strings.1.html).

{% highlight bash mark_lines="4 5 6 7 8 9 10" %}
$ strings -n 24 -o '*.m4a'

7724    com.apple.VoiceMemos (iPhone Version 18.5 (Build 22F76))
7438979 tsrp{
  "attributedString":{
    "attributeTable":[{"timeRange":[0,2.52]},{"timeRange":[2.52,2.7]},{"timeRange":[2.7,2.88]},{"timeRange":[2.88,3.12]},{"timeRange":  [3.12,3.72]},{"timeRange":[3.72,4.74]},{"timeRange":[4.74,4.92]},{"timeRange":[4.92,5.22]},{"timeRange":[5.22,5.34]},{"timeRange":[5.34,5.52]},{"timeRange":[5.52,5.7]},{"timeRange":[5.7,6.6]},{"timeRange":[6.6,6.78]},{"timeRange":  [6.78,6.96]},{"timeRange":[6.96,7.2]},...],
    "runs":["OK,",0," I",1," went",2," back",3," and",4," re",5," read",6," at",7," least",8," the",9," beginning",10," of",11,  " the",12," Google",13," paper",14,...]
  },
  "locale":{"identifier":"en_US","current":0}
}
7607856 date2025-06-08T08:46:16Z
7607958 Self-Replicators Metrics & Analysis Architecture

# -n <number>: The minimum string length to print
# -o: Preceded each string by its offset (in decimal)
{% endhighlight %}

Sure enough, `strings` reveals that, starting at byte `7438979`, the `.m4a` file contains a JSON-esque string which has some of my _Voice Memos_ transcript in it.

If it really was JSON (spoiler: it was, except for the "`tsrp`" part before the opening brace), then we should be able to extract and parse it.

## Step 3: JSON Extraction

Sticking to the commandline, let's use a few more tools for wrangling this text.

1. [`strings`](https://manpages.debian.org/testing/binutils-common/strings.1.en.html), as before, will output printable strings,
2. [`rg`](https://manpages.debian.org/testing/ripgrep/rg.1.en.html), will filter for that `tsrp` prefix,
3. [`sed`](https://manpages.debian.org/testing/sed/sed.1.en.html), will remove the prefix and leave just the JSON, and finally,
4. [`jq`](https://manpages.debian.org/testing/jq/jq.1.en.html), will let us explore and manipulate the payload.

_Author's note: this was a very exploratory and iterative process, especially the `jq` code. I've written a tool called `ijq` to help with this. You can read about it here: [Interactive jq](/memo/2025/01/31/interactive-jq)_

The first thing I'm interested in is the structure of the JSON.

```bash
  # Extract printable strings from the audio file
$ strings '*.m4a' \
  # Only keep line that starts with the "tsrp" prefix
| rg 'tsrp' \
  # Remove the "tsrp" prefix keep only the JSON
| sed 's/tsrp//g' \
    # Extract the paths of every key in the JSON
    # If the path is an array index, replace it with brackets
    # Join the paths with a dot
    # Remove duplicates
| jq '[paths | map(if type == "number" then "[]" else . end) | join(".")] | unique'

[
  "attributedString",
  "attributedString.attributeTable",
  "attributedString.attributeTable.[]",
  "attributedString.attributeTable.[].timeRange",
  "attributedString.attributeTable.[].timeRange.[]",
  "attributedString.runs",
  "attributedString.runs.[]",
  "locale",
  "locale.current",
  "locale.identifier"
]
```

<details>
<summary>Take a closer look at how the <code>jq</code> code works </summary>

{% highlight bash %}
$ cat demo.json
{ "foo": [ { "bar": [ 1, 2, 3 ] } ] }%

# Extract the paths of every key in the JSON
$ cat demo.json | jq -c '[paths]'
[["foo"],["foo",0],["foo",0,"bar"],["foo",0,"bar",0],["foo",0,"bar",1],["foo",0,"bar",2]]

# If the path is an array index, replace it with
$ cat demo.json | jq -c '[paths | map(if type == "number" then "[]" else . end)]'
[["foo"],["foo","[]"],["foo","[]","bar"],["foo","[]","bar","[]"],["foo","[]","bar","[]"],["foo","[]","bar","[]"]]

# Join the paths with a dot
$ cat demo.json | jq -c '[paths | map(if type == "number" then "[]" else . end) | join(".")]'
["foo","foo.[]","foo.[].bar","foo.[].bar.[]","foo.[].bar.[]","foo.[].bar.[]"]

# Remove duplicates
$ cat demo.json | jq -c '[paths | map(if type == "number" then "[]" else . end) | join(".")] | unique'
["foo","foo.[]","foo.[].bar","foo.[].bar.[]"]
{% endhighlight %}

</details>

The transcript data is stored in an `attributedString` object, which has an `attributeTable` (an array of `timeRange` objects) and a `runs` array. The `locale` object contains the language identifier and current locale.

The actual text of the transcript is inside the `runs` array. Each word is followed by an index.


```bash
$ strings '*.m4a' \
  | rg "tsrp"  \
  | sed 's/tsrp//g'
  | jq -c '[limit(30; .attributedString.runs[])]'

 ["OK,",0," I",1," went",2," back",3," and",4," we",5," read",6," at",7," least",8," the",9," beginning",10," of",11," the",12," Google",13," paper",14]
```

The index maps to a `timeRange` in the `attributeTable` array.

Each `timeRange` is an array itself, containing two numbers: the start and end time offset of each transcribed word, in seconds.

```bash
$ strings '*.m4a' \
  | rg "tsrp"  \
  | sed 's/tsrp//g'
  | jq  -c '[limit(15; .attributedString.attributeTable[].timeRange)]'

 [[0,2.52],[2.52,2.7],[2.7,2.88],[2.88,3.12],[3.12,3.72],[3.72,4.74],[4.74,4.92],[4.92,5.22],[5.22,5.34],[5.34,5.52],[5.52,5.7],[5.7,6.6],[6.6,6.78],[6.78,6.96],[6.96,7.2]]
```

---

Let's just take a moment to pause and appreciate that, despite not knowing anything about audio formats or how text streaming works in ISO/IEC 14496-17:2006(en), we were able to find the raw transcript embedded in the `.m4a` file!

From here, we could continue wrangling and reconstruct the text.

```bash
$ ... | jq -c '[limit(30; .attributedString.runs[])] | map(if type == "string" then . else empty end) | join("")'

"OK, I went back and we read at least the beginning of the Google paper"
```

But, since the dog has already gone for a walk, I guess there's no better time than now to crack open ISO/IEC 14496, and really try to understand what's going on.

---

## Containers

`.m4a` files are a type of MPEG-4 (`.mp4`), specifically an audio-only variant. The MPEG-4 Part 14 (.mp4) standard is an implementation of the ISO Base Media File Format (Part 12 of ISO/IEC 14496).

These files are called "container formats" because they bundle together multiple different types of data.

The "A" in `.m4a` stands for "audio", but these file types can also hold things like images, video, artist metadata, chapter markers, and yes, even transcriptions.

### Atoms

The "container" is organized in a hierarchical structure of "boxes" (which Apple calls "atoms"). Each atom contains a particular piece of data related to the media being stored; like metadata, configuration, the media itself, or other nested atoms.

We can use the [`mp4dump`](https://www.bento4.com/documentation/mp4dump/) command-line tool to look at the atom structure of our `.m4a` file.

```bash
$ mp4dump '.m4a'
```

<details>
<summary>View full <code>mp4dump</code> output</summary>

{% highlight bash %}
[ftyp] size=8+20
  major_brand = `.m4a`
  minor_version = 0
  compatible_brand = `.m4a`
  compatible_brand = isom
  compatible_brand = mp42
[mdat] size=16+7279219
[moov] size=8+328928
  [mvhd] size=12+96
    timescale = 16000
    duration = 38190080
    duration(ms) = 2386880
  [trak] size=8+328457
    [tkhd] size=12+80, flags=1
      enabled = 1
      id = 1
      duration = 38190080
      width = 0.000000
      height = 0.000000
    [mdia] size=8+159480
      [mdhd] size=12+20
        timescale = 16000
        duration = 38190080
        duration(ms) = 2386880
        language = und
      [hdlr] size=12+37
        handler_type = soun
        handler_name = Core Media Audio
      [minf] size=8+159391
        [smhd] size=12+4
          balance = 0
        [dinf] size=8+28
          [dref] size=12+16
            [url ] size=12+0, flags=1
              location = [local to file]
        [stbl] size=8+159331
          [stsd] size=12+91
            entry_count = 1
            [mp4a] size=8+79
              data_reference_index = 1
              channel_count = 2
              sample_size = 16
              sample_rate = 16000
              [esds] size=12+39
                [ESDescriptor] size=5+34
                  es_id = 0
                  stream_priority = 0
                  [DecoderConfig] size=5+20
                    stream_type = 5
                    object_type = 64
                    up_stream = 0
                    buffer_size = 6144
                    max_bitrate = 24000
                    avg_bitrate = 24000
                    DecoderSpecificInfo = 14 08
                  [Descriptor:06] size=5+1
          [stts] size=12+12
            entry_count = 1
          [stsc] size=12+28
            entry_count = 2
          [stsz] size=12+149188
            sample_size = 0
            sample_count = 37295
          [stco] size=12+9952
            entry_count = 2487
    [udta] size=8+168869
      [tsrp] size=8+168861
  [udta] size=8+347
    [date] size=8+20
    [meta] size=12+307
      [hdlr] size=12+22
        handler_type = mdir
        handler_name =
      [ilst] size=8+265
        [.nam] size=8+64
          [data] size=8+56
            type = 1
            lang = 0
            value = Self-Replicators Metrics & Analysis Architecture
        [----] size=8+107
          [mean] size=8+20
            value = com.apple.iTunes
          [name] size=8+19
            value = voice-memo-uuid
          [data] size=8+44
            type = 1
            lang = 0
            value = DECAFCAFE-ABCD-ABCD-ABCD-AAAAAAAAAAAA
        [.too] size=8+70
          [data] size=8+62
            type = 1
            lang = 0
            value = com.apple.VoiceMemos (iPad Version 15.5 (Build 24F74))
{% endhighlight %}

</details>

Each atom begins with an 8-byte header (typically). The first 4 bytes specify the `atom size` (a 32-bit integer indicating the total size of the atom, including the header). The next 4 bytes specify the `type` (e.g., `ftyp`, `mdat`, `moov`), a four-character code identifying how to interpret the atom's payload.[^atomsize]

[^atomsize]: The `size` field may also contain a special value. A `0` is used to indicate that the atom is the last one in the file. A `1` is used to indicate that the atom is larger than `2^32` bytes, and it is followed by an additional 64-bit unsigned integer that contains the actual size of the atom.


_Note: `mp4dump` outputs the size as `"#{header_size}+#{payload_size}"`._

{% highlight bash mark_lines="10" %}
[ftyp] size=8+20
[moov] size=8+328928
  ...
  [trak] size=8+328457
    [tkhd] size=12+80, flags=1
    [mdia] size=8+159480
      [mdhd] size=12+20
    ...
    [udta] size=8+168869
      [tsrp] size=8+168861
...
{% endhighlight %}

The `mp4dump` output shows us the headers of each atom. Here, we can see one is of type `"tsrp"`, which matches the string we found earlier with `strings`.

`tsrp` is a "leaf" atom since it contains no child atoms in the hierarchy. Leaf atoms are the ones that usually contain media data, and this particular `tsrp` atom takes up `168861` bytes.

Apple defines what each of these atoms are for and how they're structured in their [Quicktime File Format](https://developer.apple.com/documentation/quicktime-file-format) documentation.[^isot] The documentation provides a list of the most common atoms, their types, and their purposes.

[^isot]: Which is convenient, since the real source-of-truth (ISO/IEC 14496) is not available for free.

| Atom Type | Description |
|-----------|-------------|
| `ftyp` | An atom that identifies the file type specifications with which the file is compatible. |
| `moov` | An atom that specifies the information that defines a movie. |
| `trak` | An atom that defines a single track of a movie. |
| `tkhd` | An atom that specifies the characteristics of a single track within a movie. (Required by `trak`) |
| `mdia` | An atom that describes and defines a track’s media type and sample data. (Required by `trak`) |
| `mdhd` | An atom that specifies the characteristics of a media, including time scale and duration. (Required by `mdia`) |
| `udta` | An atom where you define and store data associated with a QuickTime object, e.g. copyright. |
| `tsrp` | _NULL??_ |

As you might have noticed, I didn't include a definition for the `tsrp` atom in the table above.

This is because Apple doesn't document it, and being a custom atom, it's not part of the ISO/IEC 14496 standard itself.

All we know is that `tsrp` is a custom atom type used to store transcriptions of audio recordings in JSON.

---

I'm very curious about this:

Why doesn't Apple document their custom `tsrp` atom, similar to how they document other custom atoms?

Why have a custom atom at all? Surely there might be a suitable type already in the standards?[^4]

If not, why use a JSON string, instead of nesting `text` atoms within the `tsrp` atom?[^qtatoms]

And, what are the trade-offs to storing the transcript in SQLite, similar to _Notes_?

[^4]: Perhaps a standard timed text track (e.g., `tx3g`) within the `minf` atom could have been used?
[^qtatoms]: Or use a QT atom or atom container. See: https://developer.apple.com/documentation/quicktime-file-format/qt_atoms_and_atom_containers

---

One benefit of storing the transcript directly in the audio file is its portability. Saving the file means you also save the transcript, even outside of Apple's ecosystem.

Then again, Apple has this to say about undocumented atom types:

> If your application encounters an atom of an unknown type, it should not attempt to interpret the atom’s data. Use the atom’s size field to skip this atom and all of its contents. This allows a degree of forward compatibility with extensions to the QuickTime file format.
>
> —[QuickTime File Format/Storing and sharing media with QuickTime files/Atoms](https://developer.apple.com/documentation/quicktime-file-format/atoms#Atom-structure)

## Accessing the Transcript Atom

Ignoring Apple's advice, I've written a Ruby script to attempt to interpret this atom's data.

Using what we've discovered, the script parses atom headers, recursively traverses the hierarchy to find the `tsrp` atom, and then extracts and reconstructs the JSON payload within.

| Ruby | [https://gist.github.com/thomascountz/b84b68f](https://gist.github.com/thomascountz/b84b68f0a7c6f2f851ebc5db152b676a) |

It was a great learning experience to read through the documentation and write the Ruby script. But, to make the job even easier, we can use purpose-built tools and libraries.

[`mp4extract`](https://www.bento4.com/documentation/mp4extract/) (which comes bundled with the same tools as `mp4dump`), takes an atom path, like "`moov/trak/udta/tsrp`", and outputs its payload (using the `--payload-only` option avoids also outputting the header).

```bash
$ mp4extract --payload-only moov/trak/udta/tsrp '*.m4a' tsrp.bin
```

Once we have the payload, we can use `jq` to not only parse the JSON, but also extract the text from the `runs` array and concatenate it into a single string.

```bash
cat tsrp.bin | jq '.attributedString.runs | map(if type == "string" then . else empty end) | join("")'
```

This now means that we only need to copy-and-paste a few lines of code to get the transcripts out of _Voice Memos_ and into somewhere useful!

<ul>
  <li>Better dog dad? <mark>&nbsp;Win.</mark></li>
  <li>Thinking out loud? <mark>&nbsp;Win.</mark></li>
  <li><s>No copy-and-paste?</s> Improved workflow? <mark>&nbsp;Win.</mark></li>
</ul>

## Postscript
First, I hope you enjoyed this journey into reverse engineering Apple's _Voice Memos_ format. I had fun and I hope you did too.

If you have any questions, comments, or actually know something about this stuff, please feel free to reach out!

Oh, and if we actually want to avoid having to copy-and-paste, we can, of course, write a bash script :)

| Bash Script | [https://gist.github.com/thomascountz/287d7dd](https://gist.github.com/thomascountz/287d7dd1e04674d22a6396433937cd29) |

## Footnotes

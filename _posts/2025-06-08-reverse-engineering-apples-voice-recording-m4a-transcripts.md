---
layout: post
title: Reverse Engineering Apple's Voice Recording m4a Transcripts
date: '2025-06-08'
tags: ["ruby","reverse-engineering"]
---

Like having thoughts in the shower and working on trains, I usually get some good thinking done while walking my dog in the morning. To not lose track of all this good thinking, I've started recording voice notes on my iPhone using Apple's _Voice Memos_ app.

After recording, the app automatically generates transcriptions, allowing me to more easily make use of my memos. Unfortunately (Apple being Apple), you can't access these transcripts from anywhere outside the Voice Memos app.

---

| Just want to see the code? Check out these Gists. |  |
| --- | --- |
| [https://gist.github.com/Thomascountz/b84b68f](https://gist.github.com/Thomascountz/b84b68f0a7c6f2f851ebc5db152b676a) | Ruby  |
| [https://gist.github.com/Thomascountz/287d7dd](https://gist.github.com/Thomascountz/287d7dd1e04674d22a6396433937cd29) | Bash  |

---

_Voice Memos_ solve a lot of problems for me:

1. **I can be a better dog dad**: I used to bring a small notebook on our morning walks, but I felt rude asking my dog to wait while I scribbled something every few meters.
2. **I get to think out loud**: I've found that verbalizing my ideas helps me organize, prioritize, and clarify them.
3. **I actually use my notes**: Writing emails, drafting blog posts, making todo lists; automatic transcriptions are queryable and ready for editing.

This is what's called a "win-win-win.

## Step 0: The Problem

Unfortunately, nature has to restore the balance of so much winning by introducing an antagonist.

<mark>The only way to get the transcription text out of the <i>Voice Memos</i> app and into somewhere useful, is to clumsily copy-and-paste it.</mark>

This is an example of the worst kind of problem.

Everything is _just about_ working smoothly, but there's that _one little hiccup_ ~~that reminds you that your devices aren't really yours and neither is your data~~ that introduces friction to a workflow.

Copying-and-pasting isn't a big deal, I know. But it is _just enough_ of a deal to stop me from making use of transcriptions—which have become more valuable to me than the audio itself.

Plus, if there's anything we programmers know how to do best, it's how to write complicated automatons to avoid copying-and-pasting.

## Step 1: Find the Transcripts

Not too long ago, I was looking for a way to extract text from _Apple Notes_ (sensing a theme here?). I learned that _Notes_ are stored in a SQLite database located here:

```bash
~/Library/Group Containers/group.com.apple.notes/NoteStore.sqlite
```

Thanks to authors of tools like [apple-notes-to-sqlite](https://github.com/dogsheep/apple-notes-to-sqlite), I didn't have to decipher the complicated database schemas in order to get to my _Notes_.

I hoped the same would be true for _Voice Memos_: 1) transcripts would be stored in a SQLite database and 2) open source tools would exist for extracting them.

After finding myself on Apple StackExchange, I soon learned that I was wrong on both counts:

> Q. Where are the transcripts that are generated from recordings in the Voice Memos app stored in the file system?
>
> A. There is no documentation from Apple that I know of, but the MPEG-4 standard provides for encoding a text stream in the container itself; i.e., the *.m4a file. That must be what Voice Memos is doing. I don't see any separate file resulting from transciption [sic]. See: ISO/IEC 14496-17:2006(en) Information technology — Coding of audio-visual objects — Part 17: Streaming text format (iso.org)
>
> — [_Location of Voice Memos transcripts in the file system?_, Apple StackExchange](https://apple.stackexchange.com/questions/478073/location-of-voice-memos-transcripts-in-the-file-system)

The good news was that the audio recordings themselves could be accessed via the filesystem here:

```bash
~/Library/Group Containers/group.com.apple.VoiceMemos.shared/Recordings/
```

The bad news was that I didn't know anything about audio file formats or what "...encoding a text stream in the container itself..." meant.

## Step 2: Explore the Files

To postpone having to open up Part 17 of ISO/IEC 14496-17:2006(en), I thought I'd just poke around the `.m4a` files a bit.

If you try opening one of those files in a text editor, you'll see that it is not meant to be read by humans. But, there are often useful plaintext strings used within various binary formats. Searching for these hidden strings is one of the first steps in reverse engineering an unknown file format.

If Apple is encoding transcripts directly within the `.m4a` file, as the StackExchange answer suggested, we should be able to see it using a command line tool called [`strings`](https://manpages.ubuntu.com/manpages/questing/en/man1/strings.1.html).

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

Sure enough, `strings` reveals that, beginning at byte `7438979`, the `.m4a` file contains a JSON-looking string that contains some words from my recording.

If it really was JSON (spoiler: it was, except for the "`tsrp`" before the opening bracket), then we should be able to extract the entire string at offset `7438979` and parse it.

## Step 3: JSON Extraction

We'll begin by doing a bit of string wrangling to get structure of the JSON object. This will help us understand how the data is laid out and what we can expect to find in it.

We'll use:
1. [`strings`](https://manpages.debian.org/testing/binutils-common/strings.1.en.html), as before, to output printable strings,
2. [`rg` (ripgrep)](https://manpages.debian.org/testing/ripgrep/rg.1.en.html) to filter for that `tsrp` prefix,
3. [`sed`](https://manpages.debian.org/testing/sed/sed.1.en.html) to remove the prefix, leaving just the JSON, and
4. [`jq`](https://manpages.debian.org/testing/jq/jq.1.en.html) to extract the paths of every key in the object

This was an iterative process (especially the `jq` code[^ijq]), but I eventually arrive at something like this:

[^ijq]: I've actually written a tool called `ijq` to help with this. You can read about it here: [Interactive jq](/memo/2025/01/31/interactive-jq)

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
<summary>Take a closer look at how the <code>jq</code> code works</summary>
{% highlight bash -%}
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

From this, we can see that the transcript is stored in an `attributedString` object, which has an `attributeTable` array of `timeRange` objects, and a `runs` array. The `locale` object contains the language identifier and current locale.

It's the `runs` array that contains the actual transcript text, with each word followed by a number that seems to be the index for the `timeRange` in the `attributeTable`.


```bash
$ strings '*.m4a' \
  | rg "tsrp"  \
  | sed 's/tsrp//g'
  | jq  'limit(30; .attributedString.runs[])'

"OK" 0
" I" 1
" went" 2
" back" 3
" and" 4
" re" 5
" read" 6
" at" 7
" least" 8
" the" 9
" beginning" 10
" of" 11
" the" 12
" Google" 13
" paper" 14
```

The `timeRange` arrays contains two numbers, which I assume are the start and end times of the each transcribed word in milliseconds.

```bash
$ strings '*.m4a' \
  | rg "tsrp"  \
  | sed 's/tsrp//g'
  | jq  'limit(15; .attributedString.attributeTable[].timeRange[])'

[0,2.52]
[2.52,2.7]
[2.7,2.88]
[2.88,3.12]
[3.12,3.72]
[3.72,4.74]
[4.74,4.92]
[4.92,5.22]
[5.22,5.34]
[5.34,5.52]
[5.52,5.7]
[5.7,6.6]
[6.6,6.78]
[6.78,6.96]
[6.96,7.2]
```

---

Let's just take a moment to appreciate that, despite not knowing anything about audio formats, or ISO/IEC 14496-17:2006(en) specifically, we were able to find the raw transcript embedded in the `.m4a` file!

From here, we could continue wrangling and extract the just the text.

```bash
$ ... | jq  '.attributedString.runs | map(if type == "string" then . else empty end) | join("")'
```

But, since the dog has already gone for a walked, now is a perfect time for us to keep going and maybe learn something new.

## Step 4: Getting a bit more Sophisticated

`.m4a` files are a type of MPEG-4 (`.mp4`) file, which is an implementation of the ISO Base Media File Format standard (defined in the ISO/IEC 14496-17:2006(en) we keep hearing about).

I've seen these called files called "containers," which I've learned is because they bundle together multiple different types of data. In our case, the "A" in `.m4a` stands for "audio", but the file type can also hold things like images, video, artist metadata, chapter markers, and yes, even transcriptions.

### Atoms

The "container" format is organized in a hierarchical structure of "atoms" (I don't know why they are called that, the standard just calls them "boxes"). Each atom is responsible for a specific piece of data, metadata, or configuration related to the media and how it should be played.

The tool `mp4dump` is a command-line utility that can be used to look at the atom structure of any particular `.mp4` file, including `.m4a` files.

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

Each atom has a header made up of 32-bit fields: 4-bytes for type (e.g. `ftyp`, `mdat`, `moov`, etc.) and four bytes telling us the size of the atom, including the header itself. (Note: `mp4dump` outputs the size as `header-size+payload-size`).[^3]

[^3]: There's also an "extended header" format where the type can be a UUID and the size description can take up 64-bits.

These headers are that `mp4dump` is parsing.

{% highlight bash mark_lines="11" %}
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

From the output, we can see that `"trsp"` string we found earlier with `strings`. `tsrp` is a type of atom nested inside the hierarchy of other atoms. In this particular `.m4a` file, it takes up 168,861 bytes.

What each of these atoms are for and how they're structured is publicly defined in Apple's [Quicktime File Format](https://developer.apple.com/documentation/quicktime-file-format) documentation.[^isot] The documentation provides a list of the most common atoms, their types, and their purposes.

[^isot]: The ISO/IEC 14496 standard is the real source of truth, but they are not free.

| Atom Type | Description |
|-----------|-------------|
| `ftyp` | An atom that identifies the file type specifications with which the file is compatible. |
| `moov` | An atom that specifies the information that defines a movie. |
| `trak` | An atom that defines a single track of a movie. |
| `tkhd` | An atom that specifies the characteristics of a single track within a movie. (Required by `trak`) |
| `mdia` | An atom that describes and defines a track’s media type and sample data. (Required by `trak`) |
| `mdhd` | An atom that specifies the characteristics of a media, including time scale and duration. (Required by `mdia`) |
| `udta` | An atom where you define and store data associated with a QuickTime object, e.g. copyright. |
| `tsrp` | _NULL_ |

As you might have noticed, I didn't include a definition for the `tsrp` atom in the table above. This is because Apple does not document it.

Not only does Apple not document it anywhere, it is also not defined in the ISO/IEC 14496 standards (which I've asked a friend to verify). All we know is that it's a custom atom type used by Apple, and it is used to store transcriptions of audio recordings in JSON.

This is interesting to me. Knowing what I know now, I might have guessed that any of these would have been true:

1. An existing ISO/IEC 14496 standards atom could have been used for transcriptions.[^4]
2. Apple would document the `tsrp` atom, similar to how they document other custom atoms.
3. Apple would use `text` atoms nested under `tsrp` instead of a JSON string.[^qtatoms]
4. Apple would just store the transcript in SQLite to improve interop, similar to how they store Notes.

[^4]: Perhaps there's a standard for subtitles or captions that could be used, like `minf`?
[^qtatoms]: Or use a QT atom or atom container. See: https://developer.apple.com/documentation/quicktime-file-format/qt_atoms_and_atom_containers

None of these are true, of course.

## Step 5: Accessing the Transcript Atom

One thing I do appreciate about the `tsrp` atom is the portability it provides. Since transcriptions are embedded directly within the audio file, we can copy the file anywhere and still have access to the transcript, so long as we know how to extract it.

I've written a Ruby script to do just that; using the `atom` headers to traverse the atom hierarchy, find the `tsrp` atom, and extract, parse, and concatenate the JSON string within.

| Ruby Script | [https://gist.github.com/Thomascountz/b84b68f](https://gist.github.com/Thomascountz/b84b68f0a7c6f2f851ebc5db152b676a) |

It was fun to read through the documentation and write the Ruby script. But, to make the job even easier, we can use purpose-built tools and libraries.

`mp4extract`, which comes bundled with the `mp4dump` tool we used earlier, takes an atom path, like "`moov/trak/udta/tsrp`", and outputs its payload (using the `--payload-only` option avoids also outputting the header).

```bash
$ mp4extract --payload-only moov/trak/udta/tsrp '*.m4a' tsrp.bin
```

Once we have the payload, we can use `jq` to not only parse the JSON, but also extract the text from the `runs` array and concatenate it into a single string.

```bash
cat tsrp.bin | jq '.attributedString.runs | map(if type == "string" then . else empty end) | join("")'
```

Doing this in a bash script allows `mp4extract` to use a tempfile, since we won't need it after we're done.

```bash
temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT

mp4extract --payload-only moov/trak/udta/tsrp "$1" "$temp_file"
cat "$temp_file" | jq '.attributedString.runs | map(if type == "string" then . else empty end) | join("")'
```

Unlike the Ruby script, you do need `mp4extract` and `jq`, however it does make the process much easier and more reliable than writing our own parser.[^docker]

[^docker]: And if you don't have `mp4extract` installed, you can create a Docker image to run it without installing anything... except Docker, of course...

| Bash Script | [https://gist.github.com/Thomascountz/287d7dd](https://gist.github.com/Thomascountz/287d7dd1e04674d22a6396433937cd29) |

## Conclusion

I hope you enjoyed this little journey into reverse engineering Apple's Voice Memos app. I learned a lot about audio formats, ISO standards, and how to extract data from binary files.

If you have any questions, comments, or suggestions for improvements, please feel free to reach out!

## Footnotes

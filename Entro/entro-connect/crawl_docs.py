"""Deep-crawl a GitBook space into a single markdown file.

Written because `crwl --deep-crawl` aborts the whole run (and truncates its
output file) as soon as one page comes back without markdown.
"""

import argparse
import asyncio

from crawl4ai import (
    AsyncWebCrawler,
    BFSDeepCrawlStrategy,
    BrowserConfig,
    CacheMode,
    CrawlerRunConfig,
    LXMLWebScrapingStrategy,
)


def page_markdown(result):
    markdown = getattr(result, "markdown", None)
    if markdown is None:
        return None
    text = getattr(markdown, "raw_markdown", None) or str(markdown)
    return text if text.strip() else None


async def crawl(url: str, output: str, max_pages: int, max_depth: int) -> None:
    run_config = CrawlerRunConfig(
        cache_mode=CacheMode.BYPASS,
        scraping_strategy=LXMLWebScrapingStrategy(),
        stream=True,
        deep_crawl_strategy=BFSDeepCrawlStrategy(
            max_depth=max_depth,
            max_pages=max_pages,
            include_external=False,
        ),
    )

    seen = set()
    failed = []

    with open(output, "w", encoding="utf-8") as f:
        async with AsyncWebCrawler(config=BrowserConfig(headless=True)) as crawler:
            async for result in await crawler.arun(url=url, config=run_config):
                if result.url in seen:
                    continue
                seen.add(result.url)

                text = page_markdown(result)
                if text is None:
                    failed.append(result.url)
                    print(f"skip  {result.url}")
                    continue

                f.write(f"\n\n{'=' * 60}\n# {result.url}\n{'=' * 60}\n\n")
                f.write(text)
                f.flush()
                print(f"ok    {result.url}")

        # Failures are often transient; a single-page retry recovers most of them.
        if failed:
            print(f"\nretrying {len(failed)} page(s)")
            retry_config = CrawlerRunConfig(
                cache_mode=CacheMode.BYPASS,
                scraping_strategy=LXMLWebScrapingStrategy(),
            )
            async with AsyncWebCrawler(config=BrowserConfig(headless=True)) as crawler:
                for page in list(failed):
                    result = await crawler.arun(url=page, config=retry_config)
                    text = page_markdown(result)
                    if text is None:
                        print(f"fail  {page}")
                        continue
                    failed.remove(page)
                    f.write(f"\n\n{'=' * 60}\n# {page}\n{'=' * 60}\n\n")
                    f.write(text)
                    f.flush()
                    print(f"ok    {page}")

    print(f"\nwrote {len(seen) - len(failed)} page(s) to {output}")
    if failed:
        print("unrecovered:")
        for page in failed:
            print(f"  {page}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("url", nargs="?", default="https://entro.gitbook.io/integrations")
    parser.add_argument("-O", "--output", default="integrations.md")
    parser.add_argument("--max-pages", type=int, default=300)
    parser.add_argument("--max-depth", type=int, default=4)
    args = parser.parse_args()

    asyncio.run(crawl(args.url, args.output, args.max_pages, args.max_depth))


if __name__ == "__main__":
    main()

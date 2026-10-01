<?php

declare(strict_types=1);

use Valet\Drivers\Specific\Magento2ValetDriver;

/**
 * Valet serves static files without Cache-Control, so browsers cache them by heuristic
 * and keep stale assets in developer mode. no-cache makes them revalidate, which nginx
 * answers with a 304 off its ETag when nothing changed.
 *
 * @disregard P1009 Valet's own autoloader provides this class when server.php
 * requires this file; it is never loaded through the project's autoload.
 */
class LocalValetDriver extends Magento2ValetDriver
{
    public function serveStaticFile(string $staticFilePath, string $sitePath, string $siteName, string $uri): void
    {
        header('Cache-Control: no-cache');

        /** @disregard P1009 resolved by Valet's autoloader at runtime */
        parent::serveStaticFile($staticFilePath, $sitePath, $siteName, $uri);
    }
}

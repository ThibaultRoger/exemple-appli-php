<?php

declare(strict_types=1);

namespace App\Infrastructure\FileSystem;

use App\Core\Application\Ports\CompanyFileReaderInterface;

final class JsonCompanyFileReader implements CompanyFileReaderInterface
{
    public function read(string $filePath): array
    {
        if (!is_file($filePath)) {
            throw new \RuntimeException(sprintf('File "%s" does not exist', $filePath));
        }

        $content = file_get_contents($filePath);
        if ($content === false) {
            throw new \RuntimeException(sprintf('Cannot read file "%s"', $filePath));
        }

        $data = json_decode($content, true, 512, JSON_THROW_ON_ERROR);

        if (!is_array($data)) {
            throw new \RuntimeException('Invalid JSON structure: expected array of companies');
        }

        return $data;
    }
}

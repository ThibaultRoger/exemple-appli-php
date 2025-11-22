<?php

declare(strict_types=1);

namespace App\Core\Application\Ports;

interface CompanyFileReaderInterface
{
    /**
     * @return array<int, array<string, mixed>>  Liste brute des enregistrements JSON
     */
    public function read(string $filePath): array;
}
